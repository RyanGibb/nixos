infile=${1:-$(dirname $0)/signups.xlsx}
outfile=$(dirname $0)/signups.csv
remote_file='~/allowlist_management/signups.csv'
remote_command='~/allowlist_management/update_allowlist.sh'

echo "Converting to CSV..."
sudo ssconvert "$infile" "$outfile"
echo "Copying to remote..."
scp -J rtg2@rtg2.host.cs.st-andrews.ac.uk "$outfile" minecraft@mcse.cs.st-andrews.ac.uk:"$remote_file"
echo "Updating allowlist..."
ssh -J rtg2@rtg2.host.cs.st-andrews.ac.uk minecraft@mcse.cs.st-andrews.ac.uk "$remote_command"
echo "Done"
