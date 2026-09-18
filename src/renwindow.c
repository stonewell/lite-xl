#include <stdlib.h>
#include <assert.h>
#include <stdio.h>
#include <stdbool.h>
#include "renwindow.h"

static bool force_software_renderer = false;

void renwin_set_force_software(bool force) {
  force_software_renderer = force;
}

bool renwin_get_force_software(void) {
  return force_software_renderer;
}

bool renwin_is_gpu(RenWindow *ren) {
  return ren ? ren->is_gpu : false;
}

const char* renwin_get_renderer_name(RenWindow *ren) {
  if (ren && ren->is_gpu && ren->renderer) {
    const char *name = SDL_GetRendererName(ren->renderer);
    return name ? name : "gpu";
  }
  return "software";
}

static int query_surface_scale(RenWindow *ren) {
  int w_pixels, h_pixels;
  int w_points, h_points;
  SDL_GetWindowSizeInPixels(ren->window, &w_pixels, &h_pixels);
  SDL_GetWindowSize(ren->window, &w_points, &h_points);
  /* We consider that the ratio pixel/point will always be an integer and
     it is the same along the x and the y axis. */
  if (h_points == 0) h_points = 1;
  if (h_pixels == 0) h_pixels = 1;
  if (w_points == 0) w_points = 1;
  if (w_pixels == 0) w_pixels = 1;

  int scale = w_pixels / w_points;

  return scale ? scale : 1;
}

static void renwin_cleanup_gpu(RenWindow *ren) {
  if (ren->texture) {
    SDL_DestroyTexture(ren->texture);
    ren->texture = NULL;
  }
  if (ren->renderer) {
    SDL_DestroyRenderer(ren->renderer);
    ren->renderer = NULL;
  }
  if (ren->rensurface.surface) {
    SDL_DestroySurface(ren->rensurface.surface);
    ren->rensurface.surface = NULL;
  }
  ren->is_gpu = false;
}

static bool renwin_init_software_surface(RenWindow *ren) {
  renwin_cleanup_gpu(ren);

  SDL_Surface *surface = SDL_GetWindowSurface(ren->window);
  if (!surface) {
    fprintf(stderr, "Error getting window surface: %s\n", SDL_GetError());
    return false;
  }
  ren->rensurface.surface = surface;
  ren->rensurface.scale = 1;
  ren->is_gpu = false;
  renwin_update_scale(ren);
  return true;
}

static bool setup_renderer(RenWindow *ren, int w, int h) {
  /* Note that w and h here should always be in pixels and obtained from
     a call to SDL_GetWindowSizeInPixels(). */
  if (!ren->renderer) {
    ren->renderer = SDL_CreateRenderer(ren->window, "direct3d11,direct3d12,gpu,vulkan,metal,opengl");
    if (!ren->renderer) {
      ren->renderer = SDL_CreateRenderer(ren->window, NULL);
    }
    if (!ren->renderer) {
      fprintf(stderr, "Warning: SDL_CreateRenderer failed: %s. Falling back to software rendering.\n", SDL_GetError());
      return false;
    }
  }
  if (ren->texture) {
    SDL_DestroyTexture(ren->texture);
    ren->texture = NULL;
  }
  ren->texture = SDL_CreateTexture(ren->renderer, ren->rensurface.surface->format, SDL_TEXTUREACCESS_STREAMING, w, h);
  if (!ren->texture) {
    fprintf(stderr, "Warning: SDL_CreateTexture failed: %s. Falling back to software rendering.\n", SDL_GetError());
    SDL_DestroyRenderer(ren->renderer);
    ren->renderer = NULL;
    return false;
  }
  ren->rensurface.scale = query_surface_scale(ren);
  return true;
}

static bool renwin_init_gpu_surface(RenWindow *ren) {
  if (ren->rensurface.surface) {
    SDL_DestroySurface(ren->rensurface.surface);
    ren->rensurface.surface = NULL;
  }
  int w, h;
  SDL_GetWindowSizeInPixels(ren->window, &w, &h);
  SDL_PixelFormat format = SDL_GetWindowPixelFormat(ren->window);
  ren->rensurface.surface = SDL_CreateSurface(w, h, format == SDL_PIXELFORMAT_UNKNOWN ? SDL_PIXELFORMAT_BGRA32 : format);
  if (!ren->rensurface.surface) {
    fprintf(stderr, "Warning: SDL_CreateSurface failed: %s. Falling back to software rendering.\n", SDL_GetError());
    renwin_cleanup_gpu(ren);
    return false;
  }
  if (!setup_renderer(ren, w, h)) {
    renwin_cleanup_gpu(ren);
    return false;
  }
  ren->is_gpu = true;
  ren->scale_x = ren->scale_y = 1;
  return true;
}

void renwin_init_surface(RenWindow *ren) {
  ren->scale_x = ren->scale_y = 1;
  bool success = false;
  if (!force_software_renderer) {
    success = renwin_init_gpu_surface(ren);
  }
  if (!success) {
    if (!renwin_init_software_surface(ren)) {
      fprintf(stderr, "Fatal: Both GPU and software surface initialization failed!\n");
      exit(1);
    }
  }
}

void renwin_init_command_buf(RenWindow *ren) {
  ren->command_buf = NULL;
  ren->command_buf_idx = 0;
  ren->command_buf_size = 0;
}

static RenRect scaled_rect(const RenRect rect, const int scale) {
  return (RenRect) {rect.x * scale, rect.y * scale, rect.width * scale, rect.height * scale};
}

void renwin_clip_to_surface(RenWindow *ren) {
  SDL_SetSurfaceClipRect(renwin_get_surface(ren).surface, NULL);
}

void renwin_set_clip_rect(RenWindow *ren, RenRect rect) {
  RenSurface rs = renwin_get_surface(ren);
  RenRect sr = scaled_rect(rect, rs.scale);
  SDL_SetSurfaceClipRect(rs.surface, &(SDL_Rect){.x = sr.x, .y = sr.y, .w = sr.width, .h = sr.height});
}

RenSurface renwin_get_surface(RenWindow *ren) {
  if (ren->is_gpu) {
    return ren->rensurface;
  }
  SDL_Surface *surface = SDL_GetWindowSurface(ren->window);
  if (!surface) {
    fprintf(stderr, "Error getting window surface: %s\n", SDL_GetError());
    exit(1);
  }
  return (RenSurface){.surface = surface, .scale = 1};
}

void renwin_resize_surface(RenWindow *ren) {
  if (ren->is_gpu) {
    int new_w, new_h, new_scale;
    SDL_GetWindowSizeInPixels(ren->window, &new_w, &new_h);
    new_scale = query_surface_scale(ren);
    /* Note that (w, h) may differ from (new_w, new_h) on retina displays. */
    if (new_scale != ren->rensurface.scale ||
        new_w != ren->rensurface.surface->w ||
        new_h != ren->rensurface.surface->h) {
      if (!renwin_init_gpu_surface(ren)) {
        renwin_init_software_surface(ren);
      }
      renwin_clip_to_surface(ren);
    }
  } else {
    renwin_init_software_surface(ren);
    renwin_clip_to_surface(ren);
  }
}

void renwin_update_scale(RenWindow *ren) {
  if (!ren->is_gpu) {
    SDL_Surface *surface = SDL_GetWindowSurface(ren->window);
    if (!surface) {
      fprintf(stderr, "Error getting window surface: %s\n", SDL_GetError());
      return;
    }
    int window_w = surface->w, window_h = surface->h;
    SDL_GetWindowSize(ren->window, &window_w, &window_h);
    if (window_w > 0 && window_h > 0) {
      ren->scale_x = (float)surface->w / window_w;
      ren->scale_y = (float)surface->h / window_h;
    } else {
      ren->scale_x = ren->scale_y = 1;
    }
  } else {
    ren->scale_x = ren->scale_y = 1;
  }
}

void renwin_show_window(RenWindow *ren) {
  SDL_ShowWindow(ren->window);
}

void renwin_update_rects(RenWindow *ren, RenRect *rects, int count) {
  if (ren->is_gpu) {
    const int scale = ren->rensurface.scale;
    for (int i = 0; i < count; i++) {
      const RenRect *r = &rects[i];
      const int x = scale * r->x, y = scale * r->y;
      const int w = scale * r->width, h = scale * r->height;
      const SDL_Rect sr = {.x = x, .y = y, .w = w, .h = h};
      uint8_t *pixels = ((uint8_t *) ren->rensurface.surface->pixels) + y * ren->rensurface.surface->pitch + x * SDL_BYTESPERPIXEL(ren->rensurface.surface->format);
      SDL_UpdateTexture(ren->texture, &sr, pixels, ren->rensurface.surface->pitch);
    }
    SDL_RenderTexture(ren->renderer, ren->texture, NULL, NULL);
    SDL_RenderPresent(ren->renderer);
  } else {
    SDL_UpdateWindowSurfaceRects(ren->window, (SDL_Rect*) rects, count);
  }
}

void renwin_free(RenWindow *ren) {
  renwin_cleanup_gpu(ren);
  SDL_DestroyWindow(ren->window);
  ren->window = NULL;
}
