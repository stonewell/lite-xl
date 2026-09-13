#ifndef API_BUFFER_H
#define API_BUFFER_H

#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>
#include <lua.h>
#include <lauxlib.h>

#define API_TYPE_BUFFER "Buffer"

typedef enum {
  BUFFER_SRC_MMAP,   /* Read-only mmap from disk (vis architecture) */
  BUFFER_SRC_HEAP    /* Dynamically appended in-memory text */
} BufferSourceType;

typedef struct PieceNode {
  struct PieceNode *parent, *left, *right;
  uint8_t color;             /* RED = 0, BLACK = 1 */
  BufferSourceType source;   /* mmap or heap */
  size_t offset;             /* byte offset into the buffer source */
  size_t length;             /* byte length of this piece */
  size_t line_feed_cnt;      /* number of '\n' in this piece */

  /* Augmented Red-Black Tree Metadata (VS Code architecture) */
  size_t size_left;          /* sum of length in left subtree */
  size_t lf_cnt_left;        /* sum of line_feed_cnt in left subtree */
} PieceNode;

typedef struct {
  PieceNode *root;
  PieceNode *nil_node;       /* Sentinel black node */
  const char *mmap_data;     /* Mapped file pointer (NULL if new file) */
  size_t mmap_size;
  char *heap_data;           /* Append buffer for typed text */
  size_t heap_size;
  size_t heap_capacity;
  size_t total_size;         /* Total byte size of document */
  size_t total_lines;        /* Total line count (lf_cnt + 1) */
  int fd;                    /* File descriptor for mmap or -1 */
} TextBuffer;

int luaopen_buffer(lua_State *L);

#endif
