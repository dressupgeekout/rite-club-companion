#include <mruby.h>
#include <mruby/compile.h>

int
main(void)
{
  mrb_state *mrb = mrb_open();
  mrb_load_string(mrb, "Dir.mkdir '/tmp/xxx'");
  mrb_load_string(mrb, "Dir.delete '/tmp/xxx'");
  mrb_close(mrb);
  return 0;
}
