#include <SDL3/SDL.h>
#include <stdbool.h>
#include "renderer.h"

struct RenWindow {
  SDL_Window *window;
  uint8_t *command_buf;
  size_t command_buf_idx;
  size_t command_buf_size;
  float scale_x;
  float scale_y;
  bool is_gpu;
  SDL_Renderer *renderer;
  SDL_Texture *texture;
  RenSurface rensurface;
};
typedef struct RenWindow RenWindow;

void renwin_init_surface(RenWindow *ren);
void renwin_init_command_buf(RenWindow *ren);
void renwin_clip_to_surface(RenWindow *ren);
void renwin_set_clip_rect(RenWindow *ren, RenRect rect);
void renwin_resize_surface(RenWindow *ren);
void renwin_update_scale(RenWindow *ren);
void renwin_show_window(RenWindow *ren);
void renwin_update_rects(RenWindow *ren, RenRect *rects, int count);
void renwin_free(RenWindow *ren);
RenSurface renwin_get_surface(RenWindow *ren);
bool renwin_is_gpu(RenWindow *ren);
const char* renwin_get_renderer_name(RenWindow *ren);
void renwin_set_force_software(bool force);
bool renwin_get_force_software(void);

