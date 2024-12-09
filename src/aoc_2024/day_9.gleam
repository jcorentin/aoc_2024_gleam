import gleam/function
import gleam/int
import gleam/list
import gleam/result
import gleam/string

fn to_file_blocks(disk_map_part: List(String), file_id: Int) -> List(String) {
  let file_id = int.to_string(file_id)
  case disk_map_part {
    [file_length, free_space_length] -> {
      let assert Ok(file_length) = int.parse(file_length)
      let file_blocks = list.repeat(file_id, file_length)
      let assert Ok(free_space_length) = int.parse(free_space_length)
      let free_blocks = list.repeat(".", free_space_length)
      list.append(file_blocks, free_blocks)
    }
    [file_length] -> {
      let assert Ok(file_length) = int.parse(file_length)
      list.repeat(file_id, file_length)
    }
    _ -> panic as "Incorrect file blocks received"
  }
}

pub fn parse(input: String) -> List(String) {
  input
  |> string.trim()
  |> string.to_graphemes()
  |> list.sized_chunk(into: 2)
  |> list.index_map(to_file_blocks)
  |> list.flatten()
}

fn reclaim_free_space(acc, defraged, free_space) {
  case defraged, free_space {
    [], _ -> acc

    [_, ..rest_blocks], [empty, ..rest_empty] ->
      reclaim_free_space([empty, ..acc], rest_blocks, rest_empty)

    [block, ..rest], [] -> reclaim_free_space([block, ..acc], rest, [])
  }
}

fn defrag(
  defraged: List(String),
  free_blocks: List(String),
  rem_blocks: List(String),
  rev_blocks: List(String),
) -> List(String) {
  case rem_blocks, rev_blocks {
    [".", ..], [".", ..rest_rev] ->
      defrag(defraged, free_blocks, rem_blocks, rest_rev)

    [".", ..rest_rem], [block, ..rest_rev] ->
      defrag([block, ..defraged], [".", ..free_blocks], rest_rem, rest_rev)

    [block, ..rest], _ ->
      defrag([block, ..defraged], free_blocks, rest, rev_blocks)

    [], _ -> reclaim_free_space([], defraged, free_blocks)
  }
}

fn checksum(checksum, block, position) {
  let block = result.unwrap(int.parse(block), 0)
  checksum + block * position
}

pub fn pt_1(input: List(String)) {
  defrag([], [], input, list.reverse(input))
  |> list.index_fold(0, checksum)
}

fn do_delete_file(
  file: List(String),
  blocks_to_search: List(List(String)),
  blocks_searched: List(List(String)),
) {
  case blocks_to_search {
    [blocks, ..rest] if blocks == file ->
      list.flatten([
        list.reverse(blocks_searched),
        [list.map(file, fn(_) { "." })],
        rest,
      ])
    [blocks, ..rest] -> do_delete_file(file, rest, [blocks, ..blocks_searched])
    [] -> panic as "File is not even in disk"
  }
}

fn delete_file(file: List(String), blocks: List(List(String))) {
  do_delete_file(file, blocks, [])
}

fn try_move_file(
  file: List(String),
  blocks_to_search: List(List(String)),
  blocks_searched: List(List(String)),
) -> Result(List(List(String)), String) {
  let file_length = list.length(file)
  case blocks_to_search {
    [] -> panic as "File is not even in disk"
    [blocks, ..] if blocks == file -> Error("File cannot be moved left")
    [[".", ..] as free_blocks, ..rest] ->
      case list.length(free_blocks) {
        n if n > file_length ->
          Ok(
            list.flatten([
              list.reverse(blocks_searched),
              [file, list.repeat(".", n - file_length)],
              delete_file(file, rest),
            ]),
          )
        n if n == file_length ->
          Ok(
            list.flatten([
              list.reverse(blocks_searched),
              [file],
              delete_file(file, rest),
            ]),
          )
        _ -> try_move_file(file, rest, [free_blocks, ..blocks_searched])
      }
    [other_file, ..rest] ->
      try_move_file(file, rest, [other_file, ..blocks_searched])
  }
}

fn compact(blocks: List(List(String))) {
  blocks
  |> list.reverse()
  |> list.fold(blocks, fn(compacted, block) {
    case block {
      [] -> compacted
      [".", ..] -> compacted
      [_, ..] as file ->
        try_move_file(file, compacted, [])
        |> result.unwrap(compacted)
    }
  })
}

pub fn pt_2(input: List(String)) {
  input
  |> list.chunk(function.identity)
  |> compact()
  |> list.flatten()
  |> list.index_fold(0, checksum)
}
