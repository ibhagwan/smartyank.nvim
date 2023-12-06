<div align="center">

# smartyank.nvim

![Neovim version](https://img.shields.io/badge/Neovim-0.7-57A143?style=flat-square&logo=neovim)

[What is SmartYank](#what-is-smartyank) • [Installation](#installation) • [Configuration](#configuration) • [Tmux](tmux)

</div>

## The copy-pasta rabbit hole

Have you ever tried to paste something from the clipboard while using neovim
and realized this wasn't the text you wanted to paste?

**If the answer is yes this plugin might be for you**

[**Take me directly to the juice**](#what-is-smartyank)

### Background

When starting to use vim/neovim I found the whole copy-pasta process a bit
counter intuitive, coming from systems where there's just one clipboard
managed by `<Cmd-c>|<Cmd-v>` getting used to registers and the way the
`clipboard` option works took some time.

At first I was mad at neovim for polluting my clipboard every time I deleted
or changed a text (using `d`, `c` or even `s`) so I used the "blackhole"
mappings in order to disable that functionality via:
```vim
nnoremap d "_d
```

But then I realized I actually wanted some of the deleted texts and I was also
"missing out" on the "true way of the vimmer" so I decided to use blackhole
mappings only with the `<leader>` key:
```vim
nnoremap <leader>d "_d
```

The above was much better, but this added to my mental overhead of having to
think before each delete/change operation if I wanted to use the default
operator or my soup'd up leader-prefix version.

In addition I also wanted separation between neovim and the system clipboard
so I started using `:set clipboard=""` which introduced yet another
sequence/keybind I needed to press in order to copy the text from the yank
register `"0` to the clipboard.

Then came copy-pasting over SSH... that required **yet an additional**
keybind/workflow of having to yank the text using OSC52 (using the wonderful
[`ojroques/vim-oscyank`](https://github.com/ojroques/vim-oscyank)).

I needed a better solution with the following requirements:
- **No changes to default neovim key mappings**
- Minimum clipboard/register pollution: only copy to clipboard when I
  intent on doing so (i.e. do not overwrite my clipboard on neovim's `dd` and
  similar operations)
- Copying over ssh should be seamless, I don't need to care or worry whether
  I'm local or remote, with or without tmux.
- Easily accessible clipboard history when using neovim

Enter "SmartYank"...


## What is SmartYank

SmartYank is an opinionated (yet customizable) yank, it utilizes the
`TextYankPost` event to detect intentional yank operations (by testing
`vim.v.operator`) and:
- Highlight yanked text
- Copy yanked text to system clipboard (regardless of `clipboard` setting)
- If tmux is available, copy to a tmux clipboard buffer (enables history)
- If ssh session is detected, use OSC52 to copy to the terminal host clipboard


## Installation


Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'ibhagwan/smartyank.nvim'
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use { 'ibhagwan/smartyank.nvim' }
```

**Notes:**
- Requires neovim > `0.7`
- Calling `require'smartyank'.setup {}` is optional


## Configuration

Configuring additional options can be done via the `setup` function:
```lua
require('smartyank').setup {
    ...
}
```

or if using a `.vim` file:
```lua
lua << EOF
require('smartyank').setup{
  ...
}
EOF
```

### Default Options

Below is a list of all default options:
```lua
require('smartyank').setup {
  highlight = {
    enabled = true,         -- highlight yanked text
    higroup = "IncSearch",  -- highlight group of yanked text
    timeout = 2000,         -- timeout for clearing the highlight
  },
  clipboard = {
    enabled = true
  },
  tmux = {
    enabled = true,
    -- remove `-w` to disable copy to host client's clipboard
    cmd = { 'tmux', 'set-buffer', '-w' }
  },
  osc52 = {
    enabled = true,
    -- escseq = 'tmux',     -- use tmux escape sequence, only enable if
                            -- you're using tmux and have issues (see #4)
    ssh_only = true,        -- false to OSC52 yank also in local sessions
    silent = false,         -- true to disable the "n chars copied" echo
    echo_hl = "Directory",  -- highlight group of the OSC52 echo message
  },
  -- By default copy is only triggered by "intentional yanks" where the
  -- user initiated a `y` motion (e.g. `yy`, `yiw`, etc). Set to `false`
  -- if you wish to copy indiscriminately:
  -- validate_yank = false,
  -- 
  -- For advanced customization set to a lua function returning a boolean
  -- for example, the default condition is:
  -- validate_yank = function() return vim.v.operator == "y" end,
}
```

## Tmux

One (of the many) advantages of using [`tmux`](https://github.com/tmux/tmux)
is the ability to view the yank history by using `<prefix>#` (by default
`<C-a>#`). 

Using [`fzf-lua`](https://github.com/ibhagwan/fzf-lua) `tmux_buffers` we can
fuzzy find the tmux paste buffers and by pressing `<CR>` copy the current
selection into the "unnamed" register for easy pasting with `p` or `P` (similar
functionality to what is achieved using
[`nvim-neoclip.lua`](https://github.com/AckslD/nvim-neoclip.lua)):

![fzf-lua-tmux](https://github.com/ibhagwan/smartyank.nvim/raw/master/fzf-lua-tmux.png)

