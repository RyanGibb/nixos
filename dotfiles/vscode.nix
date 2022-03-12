{
    "editor.fontFamily" =  "monospace, 'NotoSansMono Nerd Font'";
    "latex-workshop.view.pdf.viewer" = "tab";
    "latex-workshop.latex.tools" =  [
		{
			"name" = "latexmk";
			"command" = "latexmk";
			"args" = [
				"-synctex=1"
				"-interaction=nonstopmode"
				"-file-line-error"
				"-pdf"
				"-outdir=%OUTDIR%"
				"%DOC%"
			];
			"env" = {};
		}
		{
			"name" = "lualatexmk";
			"command" = "latexmk";
			"args" = [
				"-synctex=1"
				"-interaction=nonstopmode"
				"-file-line-error"
				"-lualatex"
				"-outdir=%OUTDIR%"
				"%DOC%"
			];
			"env" = {};
		}
		{
			"name" = "latexmk_rconly";
			"command" = "latexmk";
			"args" = [
				"%DOC%"
			];
			"env" = {};
		}
		{
			"name" = "pdflatex";
			"command" = "pdflatex";
			"args" = [
				"-synctex=1"
				"-interaction=nonstopmode"
				"-file-line-error"
				"%DOC%"
			];
			"env" = {};
		}
		{
			"name" = "bibtex";
			"command" = "bibtex";
			"args" = [
				"%DOCFILE%"
			];
			"env" = {};
		}
		{
			"name" = "rnw2tex";
			"command" = "Rscript";
			"args" = [
				"-e"
				"knitr::opts_knit$set(concordance = TRUE); knitr::knit('%DOCFILE_EXT%')"
			];
			"env" = {};
		}
		{
			"name" = "jnw2tex";
			"command" = "julia";
			"args" = [
				"-e"
				"using Weave; weave(\"%DOC_EXT%\" doctype=\"tex\")"
			];
			"env" = {};
		}
		{
			"name" = "jnw2texmintex";
			"command" = "julia";
			"args" = [
				"-e"
				"using Weave; weave(\"%DOC_EXT%\" doctype=\"texminted\")"
			];
			"env" = {};
		}
		{
			"name" = "tectonic";
			"command" = "tectonic";
			"args" = [
				"--synctex"
				"--keep-logs"
				"%DOC%.tex"
			];
			"env" = {};
		}
	];
    "editor.minimap.enabled" = false;
    "diffEditor.ignoreTrimWhitespace" = false;
    "cSpell.userWords" = [
		"automatable"
		"centricity"
		"composability"
		"datacentre"
		"datacentres"
		"deallocate"
		"exokernels"
		"handoff"
		"implmentation"
		"linearizable"
		"malloc"
		"multikernels"
		"overreliance"
		"paravirtualization"
		"retraversal"
		"siloed"
		"unikernels"
		"userspace"
		"virtuality"
		"Weiser"
		"Zigbee"
	];
    "grammarly.hideUnavailablePremiumAlerts" = true;
	"grammarly.dialect" = "british";
	"grammarly.diagnostics" = {
		"[LaTeX]" = { 
            "ignore" = ["comment" "comments"] ;
        };
	};
	"cSpell.language" = "en-GB";
	"editor.fontSize" = 16;
	"editor.suggestFontSize" = 16;
}
