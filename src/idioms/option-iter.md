# การวนซ้ำบน `Option`

## คำอธิบาย

`Option` สามารถมองได้ว่าเป็นคอนเทนเนอร์ที่บรรจุสมาชิกศูนย์ตัวหรือหนึ่งตัว โดยเฉพาะอย่างยิ่ง มันอิมพลีเมนต์ trait `IntoIterator` จึงใช้งานกับโค้ดเจเนอริกที่ต้องการชนิดเช่นนี้ได้

## ตัวอย่าง

เนื่องจาก `Option` อิมพลีเมนต์ `IntoIterator` จึงใช้เป็นอาร์กิวเมนต์ให้กับ
[`.extend()`](https://doc.rust-lang.org/std/iter/trait.Extend.html#tymethod.extend) ได้:

```rust
let turing = Some("Turing");
let mut logicians = vec!["Curry", "Kleene", "Markov"];

logicians.extend(turing);

// equivalent to
if let Some(turing_inner) = turing {
    logicians.push(turing_inner);
}
```

หากคุณต้องการต่อ `Option` เข้าไปท้าย iterator ที่มีอยู่แล้ว ส่งมันให้
[`.chain()`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.chain) ได้:

```rust
let turing = Some("Turing");
let logicians = vec!["Curry", "Kleene", "Markov"];

for logician in logicians.iter().chain(turing.iter()) {
    println!("{logician} is a logician");
}
```

พึงสังเกตว่าหาก `Option` เป็น `Some` เสมอ การใช้
[`std::iter::once`](https://doc.rust-lang.org/std/iter/fn.once.html) กับสมาชิกนั้นจะถือเป็นสำนวนมากกว่า

นอกจากนี้ เนื่องจาก `Option` อิมพลีเมนต์ `IntoIterator` เราจึงวนซ้ำบนมันด้วยลูป `for` ได้ ซึ่งเทียบเท่ากับการจับคู่ด้วย `if let Some(..)` แต่ในกรณีส่วนใหญ่คุณควรเลือกใช้แบบหลัง

## ดูเพิ่มเติม

- [`std::iter::once`](https://doc.rust-lang.org/std/iter/fn.once.html) เป็น
  อิเทอเรเตอร์ที่ให้สมาชิกพอดีหนึ่งตัว เป็นทางเลือกที่อ่านง่ายกว่าสำหรับ
  `Some(foo).into_iter()`

- [`Iterator::filter_map`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.filter_map)
  เป็นเวอร์ชันของ
  [`Iterator::map`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.map)
  ที่ปรับให้เหมาะกับการแมปฟังก์ชันซึ่งคืนค่า `Option`

- ครีต [`ref_slice`](https://crates.io/crates/ref_slice) มีฟังก์ชันสำหรับ
  แปลง `Option` เป็นสไลซ์ที่มีศูนย์หรือหนึ่งสมาชิก

- [เอกสารประกอบของ `Option<T>`](https://doc.rust-lang.org/std/option/enum.Option.html)
