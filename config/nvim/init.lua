-- Caminho de instalação: ~/.config/nvim/init.lua

-- 1. CONFIGURAÇÕES BASE
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- 2. BOOTSTRAP DO LAZY.NVIM
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 3. INJEÇÃO DE DEPENDÊNCIAS
require("lazy").setup({

  -- Plugin: nvim-treesitter (rainbow-delimiters e os custom_highlights do
  -- catppuccin abaixo -- grupos @type, @string, @variable etc. -- dependem
  -- inteiramente disso pra funcionar; sem ele ficam instalados mas inertes)
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    config = function()
      -- API nova (branch main, reescrita) -- não existe mais
      -- nvim-treesitter.configs / highlight.enable. Highlighting e indent
      -- agora são recursos nativos do Neovim, só precisam ser ligados via
      -- autocmd depois que o parser da linguagem estiver instalado.
      require("nvim-treesitter").install({
        "lua", "vim", "vimdoc", "bash", "json", "yaml",
        "markdown", "markdown_inline", "python",
        "javascript", "typescript", "html", "css", "toml",
      })
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          pcall(vim.treesitter.start)
          vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
          vim.wo[0][0].foldmethod = "expr"
        end,
      })
    end,
  },

  -- Plugin: Rainbow Delimiters (Restaurado para a Matriz Quente Original)
  {
    "HiPhish/rainbow-delimiters.nvim",
    config = function()
      vim.api.nvim_set_hl(0, "RainbowDelimiterRed", { fg = "#FF6E6E", bold = true })
      vim.api.nvim_set_hl(0, "RainbowDelimiterOrange", { fg = "#FFB86C", bold = true })
      vim.api.nvim_set_hl(0, "RainbowDelimiterYellow", { fg = "#F1FA8C", bold = true })
      vim.api.nvim_set_hl(0, "RainbowDelimiterGreen", { fg = "#85FA82", bold = true })
      vim.api.nvim_set_hl(0, "RainbowDelimiterCyan", { fg = "#8BE9FD", bold = true })
      vim.api.nvim_set_hl(0, "RainbowDelimiterBlue", { fg = "#89B4FA", bold = true })
      vim.api.nvim_set_hl(0, "RainbowDelimiterViolet", { fg = "#CAA9FA", bold = true })

      require("rainbow-delimiters.setup").setup({
        highlight = {
          "RainbowDelimiterRed", "RainbowDelimiterOrange", "RainbowDelimiterYellow",
          "RainbowDelimiterGreen", "RainbowDelimiterCyan", "RainbowDelimiterBlue",
          "RainbowDelimiterViolet",
        },
      })
    end,
  },

  -- Plugin: Catppuccin (Motor de Cores Frias + Exceções Amarelas)
  {
    "catppuccin/nvim", 
    name = "catppuccin", 
    priority = 1000, 
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", 
        transparent_background = false,
        term_colors = true,
        
        color_overrides = {
            mocha = {
                base = "#121212",   
                mantle = "#181818", 
                crust = "#0a0a0a",  
                peach = "#3F68EE",   -- Azul Principal (Antigo peach/laranja)
                maroon = "#00BFFF",  -- Azul Céu 
                mauve = "#7DB9E8",   -- Azul Suave
                blue = "#5EB8FF",    -- Azul Claro
                red = "#E5A4AA",     -- Vermelho Pastel (Mantido para linter/erros)
            },
        },
        
        custom_highlights = function(colors)
            return {
                -- Base da Interface
                Comment = { fg = "#5c6370", style = { "italic" } },
                CursorLine = { bg = "#1e1e1e" },
                Cursor = { bg = "#3F68EE" },       -- Cursor em Azul Principal
                TermCursor = { bg = "#3F68EE" },
                
                -- Cabeçalhos e Títulos (Azul Céu Intenso)
                Title = { fg = "#00BFFF", style = { "bold" } },
                LazyH1 = { fg = "#00BFFF", style = { "bold" } },
                AlphaHeader = { fg = "#00BFFF", style = { "bold" } },                
                DashboardHeader = { fg = "#00BFFF" },            

                -- ==========================================
                -- ZONA MISTA (Azuis Frios + Amarelo/Verde Intocados)
                -- ==========================================
                -- Classes, Tipos e Built-ins (Azul Céu)
                ["@type"] = { fg = "#00BFFF" },
                ["@type.builtin"] = { fg = "#00BFFF" },
                
                -- Strings e Textos (Restauradas ao Dourado/Amarelo original)
                ["@string"] = { fg = "#C5A65C" },
                
                -- Variáveis Base (Azul Pastel/Céu)
                ["@variable"] = { fg = "#D6EBFF" },
                ["@property"] = { fg = "#A3D5FF" },
                ["@field"] = { fg = "#A3D5FF" },
                
                -- Parâmetros e Membros (Ciano Claro)
                ["@variable.parameter"] = { fg = "#8BE9FD", style = { "italic" } },
                ["@variable.member"] = { fg = "#8BE9FD" },
            }
        end
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- =====================================================================
  -- Alpha-Nvim (O Palácio da Memória / Start Window)
  -- =====================================================================
  {
    "goolord/alpha-nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" }, 
    config = function()
        local startify = require("alpha.themes.startify")
        
        startify.section.header.val = {
            "                                                     ",
            "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
            "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
            "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
            "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
            "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
            "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
            "                                                     ",
        }
        
        require("alpha").setup(startify.config)
    end
  },
})
