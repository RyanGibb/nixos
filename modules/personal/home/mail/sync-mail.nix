maildir:
isync:

''
#!/usr/bin/env bash

set -e

acct="$1"
folder="$2"
accts="''${acct:-ryan@freumh.org ryan.gibb@cl.cam.ac.uk ryangibb321@gmail.com}"

maildir_mv() {
    src_path="$1"
    dst_maildir="$2"
    [ -f "$src_path" ] || return 0

    # rename the file to remove the U=<uid> and prevent mbsync errors
    subdir="$(basename "$(dirname "$src_path")")"
    file="$(basename "$src_path")"
    id="''${file%%,*}"; id="''${id%%:*}"
    flags="''${file##*,}"

    if [ "$subdir" = cur ] || [ -n "$flags" ]; then
        new_file="$id:2,$flags"
    else
        new_file="$id"
    fi

	echo "mv \"$src_path\" \"${maildir}/$dst_maildir/$subdir/$new_file\""
    mv "$src_path" "${maildir}/$dst_maildir/$subdir/$new_file"
}

maildir_mvs() {
    while read -r file; do
        maildir_mv "$file" "$1"
    done
}

set_vars() {
    account="$1"
    trash_dir=Trash
    spam_dir=Spam
    sent_dir=Sent
    drafts_dir=Drafts
    archive_dir=Archive

    if [ "$account" = "ryangibb321@gmail.com" ]; then
        trash_dir="[Gmail]/Bin"
        spam_dir="[Gmail]/Spam"
        sent_dir="[Gmail]/Sent Mail"
        drafts_dir="[Gmail]/Drafts"
        archive_dir="[Gmail]/All Mail"
    fi
    if [ "$account" = "ryan@freumh.org" ]; then
        spam_dir="Junk"
    fi
}

# PRE-SYNC
#
# Move emails between folders based on tag changes. It's important not to move
# any emails that are still tagged as new; they've been indexed by notmuch but
# haven't yet received initial tags based on what folder they arrived in using
# the post-sync logic below.
#
# Searches are carefully constructed to ensure that each email is moved at most
# one time.
for account in $accts; do
	echo "$account"
    set_vars "$account"

	echo "inbox"
    # if tagged inbox, spam, or trash but not in corresponding folder, move it
    notmuch search --output=files folder:/$account/ and not tag:new \
        and tag:inbox and not folder:$account/Inbox \
		| grep $account \
        | maildir_mvs "$account/Inbox"
	echo "trash"
    notmuch search --output=files folder:/$account/ and not tag:new \
        and tag:trash and not tag:inbox and not folder:"\"$account/$trash_dir\"" \
		| grep $account \
        | maildir_mvs "$account/$trash_dir"
	echo "spam"
    notmuch search --output=files folder:/$account/ and not tag:new \
        and tag:spam and not tag:inbox and not tag:trash and not folder:"\"$account/$spam_dir\"" \
		| grep $account \
        | maildir_mvs "$account/$spam_dir"

	echo "archive"
    # if in inbox, spam, or trash but missing corresponding tag, move to archive
    notmuch search --output=files folder:/$account/ and not tag:new and \
        "(folder:$account/Inbox and not tag:inbox)" \
        or "(folder:\"$account/$spam_dir\" and not tag:spam)" \
        or "(folder:\"$account/$trash_dir\" and not tag:qrash)" \
		| grep $account \
        | maildir_mvs "$account/$archive_dir"
done

# SYNC
set +e
${"${isync}/bin/mbsync"} "''${acct:--a}''${folder:+:$folder}" || status=$?

# POST-SYNC
#
# Update notmuch, tagging new emails based on folders. Once initial tags are
# applied, the new tag must be removed so that the above pre-sync logic to move
# emails to the correct folders based on tags will work on the next run.
for account in $accounts; do
    set_vars "$account"
    notmuch new && notmuch tag --batch <<EOF
# tag based on folder (inbox, drafts, spam, trash)
+inbox -- tag:new and folder:Inbox
+spam -- tag:new and folder:"$spam_dir"
+trash -- tag:new and folder:"$trash_dir"

# remove unread tag if in sent or drafts
-unread -- tag:new and (folder:"$sent_dir" or folder:"$drafts_dir")

# remove new tag
-new -- tag:new
EOF
    status="''${status:-$?}"
done

exit "''${status:-0}"
''

