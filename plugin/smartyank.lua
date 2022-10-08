if 1 ~= vim.fn.has("nvim-0.7.0") then
  vim.api.nvim_err_writeln "smartyank.nvim requires nvim-0.7.0 or greater."
  return
end

if vim.g.loaded_smartyank == 1 then
  return
end
vim.g.loaded_smartyank = 1

-- Run our plugin and setup the autocmd
require("smartyank")

