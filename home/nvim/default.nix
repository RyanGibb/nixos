{ pkgs, config, lib, ... }:

let
  ltex-ls-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "ltex-ls.nvim";
    version = "2.6.0";
    src = pkgs.fetchFromGitHub {
      owner = "vigoux";
      repo = "ltex-ls.nvim";
      rev = "c8139ea6b7f3d71adcff121e16ee8726037ffebd";
      sha256 = "sha256-jY3ALr6h88xnWN2QdKe3R0vvRcSNhFWDW56b2NvnTCs=";
    };
  };
  cmp-spell = pkgs.vimUtils.buildVimPlugin {
    pname = "cmp-spell";
    version = "2024-05-07";
    src = pkgs.fetchFromGitHub {
      owner = "f3fora";
      repo = "cmp-spell";
      rev = "694a4e50809d6d645c1ea29015dad0c293f019d6";
      sha256 = "Gf7HSocvHmTleVQytNYmmN+fFX7kl5sYHQSpUJc0CGI=";
    };
    meta.homepage = "https://github.com/f3fora/cmp-spell/";
  };
  vim-ledger-2024-07-15 = pkgs.vimUtils.buildVimPlugin {
    pname = "vim-ledger";
    version = "2024-07-15";
    src = pkgs.fetchFromGitHub {
      owner = "ledger";
      repo = "vim-ledger";
      rev = "dbc683e24bd5338b8c12540227a58b2d247e097a";
      sha256 = "sha256-y2f0s0aAieXtj4mSnJdH7UxQlMqJqABNVPoGLlLc57A=";
    };
    meta.homepage = "https://github.com/ledger/vim-ledger/";
  };
  calendar-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "calendar-nvim";
    version = "2024-07-23";
    src = pkgs.fetchFromGitHub {
      owner = "RyanGibb";
      repo = "calendar.nvim";
      rev = "e1ebd87eb953a91de5cba2c6eff04b127c6a894b";
      sha256 = "sha256-0iiW6dAvdS5UDbjJvXWKTDqvo/4yoFkYfDind+RuTmE=";
    };
    meta.homepage = "https://github.com/RyanGibb/calendar.nvim/";
  };
  cfg = config.custom;
in {
  options.custom.nvim-lsps = lib.mkEnableOption "nvim-lsps";

  config = {
    xdg.configFile = {
      "ftplugin/mail.vim".text = ''
        setlocal tw=72
        set formatoptions+=w
      '';
    };
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      extraPackages = with pkgs;
        [ ripgrep nixd ] ++ lib.lists.optionals cfg.nvim-lsps [
          nixfmt
          # stop complaining when launching but a devshell is better
          ocamlPackages.ocaml-lsp
          ocamlPackages.ocamlformat
          lua-language-server
          pyright
          black
          ltex-ls
          jdt-language-server
          nodejs_18
          clang-tools
          typst-lsp
        ];
      extraLuaConfig = builtins.readFile ./init.lua;
      # undo transparent background
      # + "colorscheme gruvbox";
      plugins = with pkgs.vimPlugins;
        [
          gruvbox-nvim

          {
            plugin = telescope-nvim;
            type = "lua";
            config = builtins.readFile ./telescope-nvim.lua;
          }
          telescope-fzf-native-nvim
          telescope-undo-nvim
          telescope-file-browser-nvim

          {
            plugin = trouble-nvim;
            type = "lua";
            config = ''
              require('trouble').setup {
              	icons = false,
              }
              vim.keymap.set('n', '<leader>xx', function() require('trouble').toggle() end, { desc = 'Trouble toggle' })
              vim.keymap.set('n', '<leader>xw', function() require('trouble').toggle('workspace_diagnostics') end, { desc = 'Trouble workspace' })
              vim.keymap.set('n', '<leader>xd', function() require('trouble').toggle('document_diagnostics') end, { desc = 'Trouble document' })
              vim.keymap.set('n', '<leader>xq', function() require('trouble').toggle('quickfix') end, { desc = 'Trouble quickfix' })
              vim.keymap.set('n', '<leader>xl', function() require('trouble').toggle('loclist') end, { desc = 'Trouble loclist' })
              vim.keymap.set('n', '<leader>xr', function() require('trouble').toggle('lsp_references') end, { desc = 'Trouble LSP references' })
            '';
          }
          {
            plugin = gitsigns-nvim;
            type = "lua";
            config = ''
              require('gitsigns').setup{
                on_attach = function(bufnr)
                  local gitsigns = require('gitsigns')

                  local function map(mode, l, r, opts)
                    opts = opts or {}
                    opts.buffer = bufnr
                    vim.keymap.set(mode, l, r, opts)
                  end

                  map('n', ']c', function()
                    if vim.wo.diff then
                      vim.cmd.normal({']c', bang = true})
                    else
                      gitsigns.nav_hunk('next')
                    end
                  end, { desc = 'Git next hunk' })

                  map('n', '[c', function()
                    if vim.wo.diff then
                      vim.cmd.normal({'[c', bang = true})
                    else
                      gitsigns.nav_hunk('prev')
                    end
                  end, { desc = 'Git prev hunk' })

                  map('n', '<leader>gs', gitsigns.stage_hunk, { desc = 'Git stage hunk' })
                  map('n', '<leader>gr', gitsigns.reset_hunk, { desc = 'Git reset hunk' })
                  map('v', '<leader>gs', function() gitsigns.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end, { desc = 'Git stage hunk' })
                  map('v', '<leader>gr', function() gitsigns.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end, { desc = 'Git reset hunk' })
                  map('n', '<leader>gS', gitsigns.stage_buffer, { desc = 'Git stage buffer' })
                  map('n', '<leader>gu', gitsigns.undo_stage_hunk, { desc = 'Git unstage hunk' })
                  map('n', '<leader>gR', gitsigns.reset_buffer, { desc = 'Git reset buffer' })
                  map('n', '<leader>gp', gitsigns.preview_hunk, { desc = 'Git preview hunk' })
                  map('n', '<leader>gb', function() gitsigns.blame_line{full=true} end, { desc = 'Git blame' })
                  map('n', '<leader>gtb', gitsigns.toggle_current_line_blame, { desc = 'Git toggle line blame' })
                  map('n', '<leader>gd', gitsigns.diffthis, { desc = 'Git diff index' })
                  map('n', '<leader>gD', function() gitsigns.diffthis('~') end, { desc = 'Git diff last' })
                  map('n', '<leader>gtd', gitsigns.toggle_deleted, { desc = 'Git toggle deleted' })

                  -- vih
                  map({'o', 'x'}, 'ih', ':<C-U>Git select_hunk<CR>', { desc = 'Gitsigns select hunk' })
                end
              }
            '';
          }
          {
            plugin = pkgs.overlay-unstable.vimPlugins.neogit;
            type = "lua";
            config = ''
              local neogit = require('neogit')
              neogit.setup {}
            '';
          }

          plenary-nvim
          pkgs.ripgrep

          {
            plugin = nvim-cmp;
            type = "lua";
            config = builtins.readFile ./nvim-cmp.lua;
          }
          cmp-path
          cmp-buffer
          cmp-cmdline
          cmp-spell
          {
            plugin = cmp-dictionary;
            type = "lua";
            config = ''
              require("cmp_dictionary").setup({
                paths = { "${pkgs.scowl}/share/dict/words.txt" },
                exact_length = 2,
                first_case_insensitive = true,
              })
            '';
          }

          {
            plugin = luasnip;
            type = "lua";
            config = builtins.readFile ./luasnip.lua;
          }
          cmp_luasnip
          friendly-snippets

          {
            plugin = nvim-treesitter.withAllGrammars;
            type = "lua";
            config = ''
              require'nvim-treesitter.configs'.setup {
                highlight = {
                  enable = true,
                  -- :h vimtex-faq-treesitter
                  disable = { "latex" },
                },
              }
              vim.opt.foldmethod = "expr"
              vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
              vim.opt.foldenable = false
            '';
          }
          {
            plugin = nvim-treesitter-textobjects;
            type = "lua";
            config = ''
              require'nvim-treesitter.configs'.setup {
                textobjects = {
                  select = {
                    enable = true,
                    lookahead = true,
                    keymaps = {
                      ["af"] = "@function.outer",
                      ["if"] = "@function.inner",
                      ["ac"] = "@conditional.outer",
                      ["ic"] = "@conditional.inner",
                      ["al"] = "@loop.outer",
                      ["il"] = "@loop.inner",
                    },
                    include_surrounding_whitespace = true,
                  },
                  swap = {
                    enable = true,
                    swap_next = {
                      ["<leader>a"] = "@parameter.inner",
                    },
                    swap_previous = {
                      ["<leader>A"] = "@parameter.inner",
                    },
                  },
                  move = {
                    enable = true,
                    set_jumps = true,
                    goto_next_start = {
                      ["]m"] = "@function.outer",
                    },
                    goto_next_end = {
                      ["]M"] = "@function.outer",
                    },
                    goto_previous_start = {
                      ["[m"] = "@function.outer",
                    },
                    goto_previous_end = {
                      ["[M"] = "@function.outer",
                    },
                  },
                },
              }
              -- could use some tweaking
              vim.treesitter.query.set("ocaml", "textobjects", [[
              ((value_definition (let_binding)) @function.outer)
              ((let_binding body: (_) @function.inner))
              ]])
            '';
          }

          {
            plugin = vimtex;
            type = "lua";
            config = ''
              vim.cmd("filetype plugin indent on")
              vim.cmd("syntax enable")
              vim.g.vimtex_quickfix_mode = 0
              vim.g.vimtex_view_general_viewer = 'evince'
            '';
          }
          {
            plugin = sved;
            type = "lua";
            config = ''
              vim.keymap.set('n', '<leader>lv', ':call SVED_Sync()<CR>')
            '';
          }
          cmp-omni

          {
            plugin = nvim-surround;
            type = "lua";
            config = ''
              require('nvim-surround').setup({})
            '';
          }
          {
            plugin = comment-nvim;
            type = "lua";
            config = ''
              require('Comment').setup()
            '';
          }
          {
            plugin = undotree;
            type = "lua";
            config = ''
              vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle, { desc = 'Undotree toggle' })
            '';
          }
          {
            plugin = leap-nvim;
            type = "lua";
            config = ''
              vim.keymap.set({'n', 'x', 'o'}, 's',  '<Plug>(leap-forward)', { desc = "Leap forward"} )
              vim.keymap.set({'n', 'x', 'o'}, 'S',  '<Plug>(leap-backward)', { desc = "Leap backward"} )
              vim.keymap.set({'n', 'x', 'o'}, 'gs', '<Plug>(leap-from-window)', { desc = "Leap from window"} )
            '';
          }
          {
            plugin = pkgs.overlay-unstable.vimPlugins.which-key-nvim;
            type = "lua";
            config = ''
              local wk = require('which-key')
              wk.setup({
                plugins = {
                  spelling = {
                    enabled = false
                  },
                },
                icons = { mappings = false },
                triggers = {
                  { "<leader>", mode = { "n", "v" } },
                  { "<auto>", mode = "nixsotc" },
                },
              })
              wk.add({
                { "<leader>f", group = 'Find' },
                { "<leader>l", group = 'LSP' },
                { "<leader>;", group = 'DAP' },
                { "<leader>s", group = 'Session' },
                { "<leader>t", group = 'Tab' },
                { "<leader>h", group = 'Hunk' },
                { "<leader>x", group = 'Trouble' },
                { "<leader>g", group = 'Git' },
                { "<leader>i", group = 'Insert' },
                { "<leader>o", group = 'Orgmode' },
              })
            '';
          }

          {
            plugin = pkgs.notmuch;
            runtime = let
              notmuch-style = ''
                let g:notmuch_date_format = '%Y-%m-%d'
                let g:notmuch_datetime_format = '%Y-%m-%d %I:%M%p'
              '';
            in {
              "ftplugin/notmuch-folders.vim".text = notmuch-style;
              "ftplugin/notmuch-search.vim".text = notmuch-style;
              "ftplugin/notmuch-show.vim".text = notmuch-style;
              "ftplugin/notmuch-compose.vim".text = notmuch-style;
            };
          }

          {
            plugin = vim-ledger-2024-07-15;
            type = "lua";
            config = ''
              vim.g.ledger_fuzzy_account_completion = true
              vim.g.ledger_extra_options = '--pedantic'
              vim.g.ledger_align_at = 50
              vim.g.ledger_accounts_cmd = 'ledger accounts --add-budget'

              vim.g.ledger_date_format = '%Y-%m-%d'

              vim.cmd([[
                autocmd FileType ledger nnoremap <buffer> <leader>e :call ledger#entry()<CR>
              ]])
            '';
          }
          vim-markdown

          {
            plugin = orgmode;
            type = "lua";
            config = ''
              -- Open agenda prompt: <Leader>oa
              -- Open capture prompt: <Leader>oc
              -- In any orgmode buffer press g? for help
              require('orgmode').setup({
              	org_agenda_files = { '~/vault/agenda/*.org' },
              	org_default_notes_file = '~/vault/refile.org',
              })
            '';
          }
          {
            plugin = calendar-nvim;
            type = "lua";
            config = ''
              require('calendar')
            '';
          }
        ] ++ lib.lists.optionals cfg.nvim-lsps [
          {
            plugin = nvim-lspconfig;
            type = "lua";
            config = builtins.readFile ./lsp.lua;
            runtime = let
              ml-style = ''
                setlocal expandtab
                setlocal shiftwidth=2
                setlocal tabstop=2
                setlocal softtabstop=2
              '';
            in {
              "ftplugin/nix.vim".text = ml-style;
              "ftplugin/ocaml.vim".text = ml-style;
              "ftplugin/java.lua".text = ''
                local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
                local workspace_dir = '~/.cache/jdt/' .. project_name
                require('jdtls').start_or_attach {
                	on_attach = On_attach,
                	capabilities = Capabilities,
                	cmd = { 'jdt-language-server', '-data', workspace_dir, },
                	root_dir = vim.fs.dirname(vim.fs.find({'gradlew', '.git', 'mvnw'}, { upward = true })[1]),
                }
              '';
              "ftplugin/ledger.vim".text = ''
                setlocal foldmethod=syntax
              '';
            };
          }
          {
            plugin = nvim-dap;
            type = "lua";
            config = builtins.readFile ./dap.lua;
          }
          cmp-nvim-lsp
          cmp-nvim-lsp-signature-help
          ltex-ls-nvim
          nvim-jdtls
        ];
    };
  };
}
