import gleam/bool
import gleam/deque
import gleam/int
import gleam/io
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

fn defrag(
  defraged: List(String),
  free_space_end: List(String),
  rem_file_blocks: deque.Deque(String),
) -> List(String) {
  use <- bool.guard(
    when: deque.is_empty(rem_file_blocks),
    return: list.append(list.reverse(defraged), free_space_end),
  )

  let front = deque.pop_front(rem_file_blocks)
  let back = deque.pop_back(rem_file_blocks)
  let assert Ok(#(front, without_front)) = front
  let assert Ok(#(back, without_back)) = back
  let without_front_and_back = case deque.pop_back(without_front) {
    Ok(#(_back, without_front_and_back)) -> without_front_and_back
    Error(Nil) -> deque.new()
  }

  case front, back {
    ".", "." -> defrag(defraged, [".", ..free_space_end], without_back)
    ".", file_block ->
      defrag(
        [file_block, ..defraged],
        [".", ..free_space_end],
        without_front_and_back,
      )
    file_block, _ ->
      defrag([file_block, ..defraged], free_space_end, without_front)
  }
}

fn checksum(checksum, block, position) {
  let block = result.unwrap(int.parse(block), 0)
  checksum + block * position
}

pub fn pt_1(input: List(String)) {
  input
  |> deque.from_list()
  |> defrag([], [], _)
  |> list.index_fold(0, checksum)
}

pub fn pt_2(input: List(String)) {
  todo as "part 2 not implemented"
}
