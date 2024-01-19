{
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
    "g" = ":select 0<Enter>";
    "G" = ":select -1<Enter>";
    "J" = ":next-folder<Enter>";
    "<C-Down>" = ":next-folder<Enter>";
    "K" = ":prev-folder<Enter>";
    "<C-Up>" = ":prev-folder<Enter>";
    "H" = ":collapse-folder<Enter>";
    "<C-Left>" = ":collapse-folder<Enter>";
    "L" = ":expand-folder<Enter>";
    "<C-Right>" = ":expand-folder<Enter>";
    "v" = ":mark -t<Enter>";
    "<Space>" = ":mark -t<Enter>:next<Enter>";
    "V" = ":mark -v<Enter>";
    "m" = ":read -t<Enter>";
    "t" = ":toggle-threads<Enter>";
    "T" = ":toggle-thread-context<Enter>";
    "zc" = ":fold<Enter>";
    "zo" = ":unfold<Enter>";
    "<Enter>" = ":view<Enter>";
    "d" = ":move Trash<Enter>";
    "D" = ":prompt 'Really delete this message?' 'delete-message'<Enter>";
    "<C-s>" = ":move Spam<Enter>";
    "a" = ":read<Enter>:archive flat<Enter>";
    "A" = ":unmark -a<Enter>:mark -T<Enter>:archive flat<Enter>";
    "C" = ":compose<Enter>";
    "rr" = ":reply -a<Enter>";
    "rq" = ":reply -aq<Enter>";
    "Rr" = ":reply<Enter>";
    "Rq" = ":reply -q<Enter>";
    "c" = ":cf<space>";
    "$" = ":term<space>";
    "!" = ":term<space>";
    "|" = ":pipe<space>";
    "/" = ":search<space>";
    "\\" = ":filter<space>";
    "," = "\":change-tab notmuch<Enter>:cf \"";
    "n" = ":next-result<Enter>";
    "N" = ":prev-result<Enter>";
    "<Esc>" = ":clear<Enter>";
    "s" = ":split<Enter>";
    "S" = ":vsplit<Enter>";
    "<C-r>" = ":check-mail<Enter>";
  };

  "messages:folder=Drafts" = {
    "<Enter>" = ":recall<Enter>";
  };

  view = {
    "/" = ":toggle-key-passthrough<Enter>/";
    "," = "\":change-tab notmuch<Enter>:cf \"";
    "q" = ":close<Enter>";
    "O" = ":open<Enter>";
    "o" = ":open<Enter>";
    "S" = ":save<space>";
    "|" = ":pipe<space>";
    "d" = ":move Trash<Enter>";
    "D" = ":prompt 'Really delete this message?' 'delete-message'<Enter>";
    "<C-s>" = ":move Spam<Enter>";
    "a" = ":archive flat<Enter>";
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
  };

  "view::passthrough" = {
    "$noinherit" = "true";
    "$ex" = "<C-x>";
    "<Esc>" = ":toggle-key-passthrough<Enter>";
  };

  "messages:account=all" = {
    "a" = ":read<Enter>:modify-labels -inbox +archive<Enter>";
    "A" = ":unmark -a<Enter>:mark -T<Enter>:read<Enter>:modify-labels -inbox +archive <Enter>";
    "rr" = '':reply -aA {{index (.Filename | split ("/")) 4}}<Enter>'';
    "rq" = '':reply -aqA {{index (.Filename | split ("/")) 4}}<Enter>'';
    "Rr" = '':replyA {{index (.Filename | split ("/")) 4}}<Enter>'';
    "Rq" = '':reply -qA {{index (.Filename | split ("/")) 4}}<Enter>'';
    "d" = ":modify-labels trash<Enter>";
    "<C-s>" = ":modify-labels Spam<Enter>";
  };

  "view:account=all" = {
    "a" = ":read<Enter>:modify-labels -inbox +archive<Enter>";
    "A" = ":unmark -a<Enter>:mark -T<Enter>:read<Enter>:modify-labels -inbox +archive <Enter>";
    "rr" = '':reply -aA {{index (.Filename | split ("/")) 4}}<Enter>'';
    "rq" = '':reply -aqA {{index (.Filename | split ("/")) 4}}<Enter>'';
    "Rr" = '':replyA {{index (.Filename | split ("/")) 4}}<Enter>'';
    "Rq" = '':reply -qA {{index (.Filename | split ("/")) 4}}<Enter>'';
  };

  compose = {
    "$noinherit" = "true";
    "$ex" = "<C-x>";
    "<C-k>" = ":prev-field<Enter>";
    "<C-Up>" = ":prev-field<Enter>";
    "<C-j>" = ":next-field<Enter>";
    "<C-Down>" = ":next-field<Enter>";
    "<C-Left>" = ":switch-account -p<Enter>";
    "<C-Right>" = ":switch-account -n<Enter>";
    "<C-p>" = ":prev-tab<Enter>";
    "<C-PgUp>" = ":prev-tab<Enter>";
    "<C-n>" = ":next-tab<Enter>";
    "<C-PgDn>" = ":next-tab<Enter>";
    "<tab>" = ":next-field<Enter>";
    "<backtab>" = ":prev-field<Enter>";
  };

  "compose::editor" = {
    "$noinherit" = "true";
    "$ex" = "<C-x>";
    "<C-k>" = ":prev-field<Enter>";
    "<C-Up>" = ":prev-field<Enter>";
    "<C-j>" = ":next-field<Enter>";
    "<C-Down>" = ":next-field<Enter>";
    "<C-p>" = ":prev-tab<Enter>";
    "<C-PgUp>" = ":prev-tab<Enter>";
    "<C-n>" = ":next-tab<Enter>";
    "<C-PgDn>" = ":next-tab<Enter>";
    "<C-a>" = ":attach -m<space>";
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

  "compose::review:account=all" = {
    "y" = ":send<Enter>:read<Enter>:modify-labels -inbox +archive<Enter>";
  };

  terminal = {
    "$noinherit" = "true";
    "$ex" = "<C-x>";
    "<C-p>" = ":prev-tab<Enter>";
    "<C-n>" = ":next-tab<Enter>";
    "<C-PgUp>" = ":prev-tab<Enter>";
    "<C-PgDn>" = ":next-tab<Enter>";
  };
}
