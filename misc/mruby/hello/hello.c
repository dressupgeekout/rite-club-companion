#include <mruby.h>
#include <mruby/compile.h>

int
main(void)
{
  mrb_state *mrb = mrb_open();
  mrb_load_string(mrb, "puts 'hello world ' + (2+3).to_s");
  mrb_close(mrb);
  return 0;
}
