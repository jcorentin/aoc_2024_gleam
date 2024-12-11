import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder

pub fn parse(input: String) -> List(Int) {
  input
  |> string.trim()
  |> string.split(" ")
  |> list.map(int.parse)
  |> result.all
  |> result.unwrap([])
}

fn is_even_digits(stone: Int) -> Bool {
  stone
  |> int.digits(10)
  |> result.unwrap([])
  |> list.length()
  |> int.is_even()
}

fn split_in_two_stones(stone: Int) -> List(Int) {
  let digits =
    stone
    |> int.digits(10)
    |> result.unwrap([])

  let length = list.length(digits)
  let #(first_half, second_half) = digits |> list.split(length / 2)
  let assert Ok(first_half) = first_half |> int.undigits(10)
  let assert Ok(second_half) = second_half |> int.undigits(10)
  [first_half, second_half]
}

fn transform_stone(stone: Int) -> List(Int) {
  let is_even_digits_stone = is_even_digits(stone)
  case stone {
    0 -> [1]
    stone if is_even_digits_stone -> split_in_two_stones(stone)
    n -> [n * 2024]
  }
}

fn blink(stones: List(Int)) -> List(Int) {
  stones
  |> list.flat_map(transform_stone)
}

pub fn pt_1(input: List(Int)) {
  yielder.iterate(input, blink)
  |> yielder.at(25)
  |> result.unwrap([])
  |> list.length()
}

type Cache =
  Dict(#(Int, Int), Int)

fn count_stones(
  stone: Int,
  remaining_blinks: Int,
  cache: Cache,
) -> #(Int, Cache) {
  let cached_result =
    dict.get(cache, #(stone, remaining_blinks))
    |> result.map(fn(result) { #(result, cache) })

  use <- result.lazy_unwrap(cached_result)
  let memoize = fn(cache, value) {
    dict.insert(cache, #(stone, remaining_blinks), value)
  }
  case transform_stone(stone), remaining_blinks {
    [_], 1 -> #(1, memoize(cache, 1))
    [_, _], 1 -> #(2, memoize(cache, 2))
    [next_stone], blinks -> {
      let #(count, cache) = count_stones(next_stone, blinks - 1, cache)
      #(count, memoize(cache, count))
    }
    [next_stone_left, next_stone_right], blinks -> {
      let #(count_left, cache) =
        count_stones(next_stone_left, blinks - 1, cache)
      let #(count_right, cache) =
        count_stones(next_stone_right, blinks - 1, cache)
      let count = count_left + count_right
      #(count, memoize(cache, count))
    }
    _, _ -> panic as "Unexpected stone transform"
  }
}

pub fn pt_2(input: List(Int)) {
  let #(count, _cache) =
    input
    |> list.fold(#(0, dict.new()), fn(acc, stone) {
      let #(acc_count, acc_cache) = acc
      let #(count, cache) = count_stones(stone, 75, acc_cache)
      #(count + acc_count, cache)
    })
  count
}
