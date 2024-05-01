{ pkgs, ... }: {
  global = {
    "<C-p>" = ":prev-tab<Enter>";
    "<C-PgUp>" = ":prev-tab<Enter>";
    "<C-n>" = ":next-tab<Enter>";
    "<C-PgDn>" = ":next-tab<Enter>";
    "<C-t>" = ":term<Enter>";
    "?" = ":help keys<Enter>";
    "<C-c>" = ":prompt 'Quit?' quit<Enter>";
  };

  messages = {
    "q" = ":quit<Enter>";
    "j" = ":next<Enter>";
    "<Down>" = ":next<Enter>";
    "<C-d>" = ":next 50%<Enter>";
    "<C-f>" = ":next 100%<Enter>";
    "<PgDn>" = ":next 100%<Enter>";
    "k" = ":prev<Enter>";
    "<Up>" = ":prev<Enter>";
    "<C-u>" = ":prev 50%<Enter>";
    "<C-b>" = ":prev 100%<Enter>";
    "<PgUp>" = ":prev 100%<Enter>";
    "gg" = ":select 0<Enter>";
    "G" = ":select -1<Enter>";
    "gi" = ":cf Inbox<Enter>";
    "gs" = ":cf Sent<Enter>";
    "gd" = ":cf Drafts<Enter>";
    "ga" = ":cf Archive<Enter>";
    "gS" = ":cf Spam<Enter>";
    "gb" = ":cf Bin<Enter>";
    "Mi" = ":move Inbox<Enter>";
    "Ms" = ":move Sent<Enter>";
    "Md" = ":move Drafts<Enter>";
    "Ma" = ":move Archive<Enter>";
    "MS" = ":move Spam<Enter>";
    "Mb" = ":move Bin<Enter>";
    "J" = ":next-folder<Enter>";
    "<C-j>" = ":next-folder<Enter>";
    "<C-Down>" = ":next-folder<Enter>";
    "K" = ":prev-folder<Enter>";
    "<C-k>" = ":prev-folder<Enter>";
    "<C-Up>" = ":prev-folder<Enter>";
    "H" = ":collapse-folder<Enter>";
    "<C-h>" = ":collapse-folder<Enter>";
    "<C-Left>" = ":collapse-folder<Enter>";
    "L" = ":expand-folder<Enter>";
    "<C-l>" = ":expand-folder<Enter>";
    "<C-Right>" = ":expand-folder<Enter>";
    "v" = ":mark -t<Enter>";
    "<Space>" = ":mark -t<Enter>:next<Enter>";
    "V" = ":mark -v<Enter>";
    "m" = ":read -t<Enter>";
    "," = ":read<Enter>";
    "." = ":unread<Enter>";
    "t" = ":toggle-threads<Enter>";
    "T" = ":toggle-thread-context<Enter>";
    "zc" = ":fold<Enter>";
    "zo" = ":unfold<Enter>";
    "za" = ":fold -t<Enter>";
    "zM" = ":fold -a<Enter>";
    "zR" = ":unfold -a<Enter>";
    "<Enter>" = ":view<Enter>";
    "d" = ":read<Enter>:move Bin<Enter>";
    "D" = ":prompt 'Really delete this message?' 'delete-message'<Enter>";
    "<C-s>" = ":read<Enter>:move Spam<Enter>";
    "a" = ":read<Enter>:archive flat<Enter>";
    "A" = ":unmark -a<Enter>:mark -T<Enter>:read<Enter>:archive flat<Enter>";
    "c" = ":compose<Enter>";
    "rr" = ":reply -a<Enter>";
    "rq" = ":reply -aq<Enter>";
    "Rr" = ":reply<Enter>";
    "Rq" = ":reply -q<Enter>";
    "f" = ":cf";
    "$" = ":term<space>";
    "!" = ":term<space>";
    "|" = ":pipe<space>";
    "/" = ":search<space>";
    "\\" = ":filter<space>";
    "n" = ":next-result<Enter>";
    "N" = ":prev-result<Enter>";
    "<Esc>" = ":clear<Enter>";
    "s" = ":split<Enter>";
    "S" = ":vsplit<Enter>";
    "<C-r>" = ":check-mail<Enter>";
    "<C-a>" = ":mark -a<Enter>";
    "e" = ":envelope<Enter>";
    "E" = ":envelope -h<Enter>";
  };

  "messages:folder=Drafts" = { "<Enter>" = ":recall<Enter>"; };

  view = {
    "/" = ":toggle-key-passthrough<Enter>/";
    "q" = ":close<Enter>";
    "O" = ":open<Enter>";
    "o" = ":open<Enter>";
    "c" =
      ":open ${pkgs.libsForQt5.kitinerary}/libexec/kf5/kitinerary-extractor -o ical {} | khal import --batch";
    "S" = ":save<space>";
    "|" = ":pipe<space>";
    "d" = ":read<Enter>:move Bin<Enter>";
    "D" = ":prompt 'Really delete this message?' 'delete-message'<Enter>";
    "<C-s>" = ":read<Enter>:move Spam<Enter>";
    "a" = ":read<Enter>:archive flat<Enter>";
    "A" = ":unmark -a<Enter>:mark -T<Enter>:read<Enter>:archive flat<Enter>";
    "<C-l>" = ":open-link <space>";
    "f" = ":forward<Enter>";
    "rr" = ":reply -a<Enter>";
    "rq" = ":reply -aq<Enter>";
    "Rr" = ":reply<Enter>";
    "Rq" = ":reply -q<Enter>";
    "H" = ":toggle-headers<Enter>";
    "<C-k>" = ":prev-part<Enter>";
    "<C-Up>" = ":prev-part<Enter>";
    "<C-j>" = ":next-part<Enter>";
    "<C-Down>" = ":next-part<Enter>";
    "J" = ":next<Enter>";
    "<C-Right>" = ":next<Enter>";
    "K" = ":prev<Enter>";
    "<C-Left>" = ":prev<Enter>";
    "e" = ":envelope<Enter>";
    "E" = ":envelope -h<Enter>";
  };

  "view::passthrough" = {
    "$noinherit" = "true";
    "$ex" = "<C-x>";
    "<Esc>" = ":toggle-key-passthrough<Enter>";
  };

  compose = {
    "$noinherit" = "true";
    "$ex" = "<C-x>";
    "<C-c>" = ":cc";
    "<C-b>" = ":bcc";
    "<C-k>" = ":prev-field<Enter>";
    "<C-Up>" = ":prev-field<Enter>";
    "<C-j>" = ":next-field<Enter>";
    "<C-Down>" = ":next-field<Enter>";
    "<C-h>" = ":switch-account -p<Enter>";
    "<C-Left>" = ":switch-account -p<Enter>";
    "<C-l>" = ":switch-account -n<Enter>";
    "<C-Right>" = ":switch-account -n<Enter>";
    "<C-p>" = ":prev-tab<Enter>";
    "<C-PgUp>" = ":prev-tab<Enter>";
    "<C-n>" = ":next-tab<Enter>";
    "<C-PgDn>" = ":next-tab<Enter>";
    "<tab>" = ":next-field<Enter>";
    "<backtab>" = ":prev-field<Enter>";
    "<C-a>" = ":attach -m<Enter>";
    "<C-q>" = ":abort<Enter>";
  };

  "compose::editor" = {
    "$noinherit" = "true";
    "$ex" = "<exit>";
    "<C-k>" = ":prev-field<Enter>";
    "<C-Up>" = ":prev-field<Enter>";
    "<C-j>" = ":next-field<Enter>";
    "<C-Down>" = ":next-field<Enter>";
    "<C-h>" = ":switch-account -p<Enter>";
    "<C-l>" = ":switch-account -n<Enter>";
    "<C-p>" = ":prev-tab<Enter>";
    "<C-PgUp>" = ":prev-tab<Enter>";
    "<C-n>" = ":next-tab<Enter>";
    "<C-PgDn>" = ":next-tab<Enter>";
    "<C-a>" = ":attach -m<Enter>";
    "<C-q>" = ":abort<Enter>";
  };

  "compose::review" = {
    "y" = ":send -a flat<Enter>";
    "Y" = ":send<Enter>";
    "q" = ":abort<Enter>";
    "v" = ":preview<Enter>";
    "p" = ":postpone<Enter>";
    "e" = ":edit<Enter>";
    "a" = ":attach -m<space>";
    "d" = ":detach<space>";
  };

  terminal = {
    "$noinherit" = "true";
    "$ex" = "<C-x>";
    "<C-p>" = ":prev-tab<Enter>";
    "<C-n>" = ":next-tab<Enter>";
    "<C-PgUp>" = ":prev-tab<Enter>";
    "<C-PgDn>" = ":next-tab<Enter>";
  };

  "messages:account=ryangibb321@gmail.com" = {
    "ga" = ":cf [Gmail]/'All Mail'<Enter>";
    "gs" = ":cf [Gmail]/'Sent Mail'<Enter>";
    "Ma" = ":move [Gmail]/'All Mail'<Enter>";
    "Ms" = ":move [Gmail]/'Sent Mail'<Enter>";
  };
}
