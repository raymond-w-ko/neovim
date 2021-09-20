local helpers = require('test.functional.helpers')(after_each)

local eq = helpers.eq
local clear = helpers.clear
local command = helpers.command
local eval = helpers.eval
local meths = helpers.meths
local exec_capture = helpers.exec_capture
local source = helpers.source
local nvim_dir = helpers.nvim_dir

before_each(clear)

describe(':let', function()
  it('correctly lists variables with curly-braces', function()
    meths.set_var('v', {0})
    eq('v                     [0]', exec_capture('let {"v"}'))
  end)

  it('correctly lists variables with subscript', function()
    meths.set_var('v', {0})
    eq('v[0]                  #0', exec_capture('let v[0]'))
    eq('g:["v"][0]            #0', exec_capture('let g:["v"][0]'))
    eq('{"g:"}["v"][0]        #0', exec_capture('let {"g:"}["v"][0]'))
  end)

  it(":unlet self-referencing node in a List graph #6070", function()
    -- :unlet-ing a self-referencing List must not allow GC on indirectly
    -- referenced in-scope Lists. Before #6070 this caused use-after-free.
    source([=[
      let [l1, l2] = [[], []]
      echo 'l1:' . id(l1)
      echo 'l2:' . id(l2)
      echo ''
      let [l3, l4] = [[], []]
      call add(l4, l4)
      call add(l4, l3)
      call add(l3, 1)
      call add(l2, l2)
      call add(l2, l1)
      call add(l1, 1)
      unlet l2
      unlet l4
      call garbagecollect(1)
      call feedkeys(":\e:echo l1 l3\n:echo 42\n:cq\n", "t")
    ]=])
  end)

  it("multibyte env var #8398 #9267", function()
    command("let $NVIM_TEST = 'AìaB'")
    eq('AìaB', eval('$NVIM_TEST'))
    command("let $NVIM_TEST = 'AaあB'")
    eq('AaあB', eval('$NVIM_TEST'))
    local mbyte = [[\p* .ม .ม .ม .ม่ .ม่ .ม่ ֹ ֹ ֹ .ֹ .ֹ .ֹ ֹֻ ֹֻ ֹֻ
                    .ֹֻ .ֹֻ .ֹֻ ֹֻ ֹֻ ֹֻ .ֹֻ .ֹֻ .ֹֻ ֹ ֹ ֹ .ֹ .ֹ .ֹ ֹ ֹ ֹ .ֹ .ֹ .ֹ ֹֻ ֹֻ
                    .ֹֻ .ֹֻ .ֹֻ a a a ca ca ca à à à]]
    command("let $NVIM_TEST = '"..mbyte.."'")
    eq(mbyte, eval('$NVIM_TEST'))
  end)

  it("multibyte env var to child process #8398 #9267",  function()
    local cmd_get_child_env = "let g:env_from_child = system(['"..nvim_dir.."/printenv-test', 'NVIM_TEST'])"
    command("let $NVIM_TEST = 'AìaB'")
    command(cmd_get_child_env)
    eq(eval('$NVIM_TEST'), eval('g:env_from_child'))

    command("let $NVIM_TEST = 'AaあB'")
    command(cmd_get_child_env)
    eq(eval('$NVIM_TEST'), eval('g:env_from_child'))

    local mbyte = [[\p* .ม .ม .ม .ม่ .ม่ .ม่ ֹ ֹ ֹ .ֹ .ֹ .ֹ ֹֻ ֹֻ ֹֻ
                    .ֹֻ .ֹֻ .ֹֻ ֹֻ ֹֻ ֹֻ .ֹֻ .ֹֻ .ֹֻ ֹ ֹ ֹ .ֹ .ֹ .ֹ ֹ ֹ ֹ .ֹ .ֹ .ֹ ֹֻ ֹֻ
                    .ֹֻ .ֹֻ .ֹֻ a a a ca ca ca à à à]]
    command("let $NVIM_TEST = '"..mbyte.."'")
    command(cmd_get_child_env)
    eq(eval('$NVIM_TEST'), eval('g:env_from_child'))
  end)

  it("release of list assigned to l: variable does not trigger assertion #12387, #12430", function()
    source([[
      func! s:f()
        let l:x = [1]
        let g:x = l:
      endfunc
      for _ in range(2)
        call s:f()
      endfor
      call garbagecollect()
      call feedkeys('i', 't')
    ]])
    eq(1, eval('1'))
  end)
end)
