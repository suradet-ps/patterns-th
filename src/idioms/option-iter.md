# การวนซ้ำบน `Option`

## คำอธิบาย

เราสามารถมอง `Option` เสมือนเป็น Container ที่บรรจุข้อมูลได้ 0 หรือ 1 ตัว โดยเฉพาะอย่างยิ่ง `Option` ได้อิมพลีเมนต์ trait `IntoIterator` ไว้อยู่แล้ว จึงสามารถนำไปใช้งานร่วมกับโค้ดเชิงเจเนอริกที่ต้องการ Iterator ได้อย่างแนบเนียน

## ตัวอย่าง

เนื่องจาก `Option` อิมพลีเมนต์ `IntoIterator` เราจึงสามารถส่งมันเป็นอาร์กิวเมนต์ให้กับเมท็อด [`.extend()`](https://doc.rust-lang.org/std/iter/trait.Extend.html#tymethod.extend) ได้โดยตรง:

```rust
let turing = Some("Turing");
let mut logicians = vec!["Curry", "Kleene", "Markov"];

logicians.extend(turing);

// equivalent to
if let Some(turing_inner) = turing {
    logicians.push(turing_inner);
}
```

หากคุณต้องการต่อท้ายค่าจาก `Option` เข้ากับ Iterator ที่มีอยู่เดิม ก็สามารถส่งมันเข้าไปในเมท็อด [`.chain()`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.chain) ได้ทันที:

```rust
let turing = Some("Turing");
let logicians = vec!["Curry", "Kleene", "Markov"];

for logician in logicians.iter().chain(turing.iter()) {
    println!("{logician} is a logician");
}
```

ข้อสังเกต: หากแน่ใจว่าค่าใน `Option` นั้นมีค่าเป็น `Some` เสมอ การเลือกใช้ [`std::iter::once`](https://doc.rust-lang.org/std/iter/fn.once.html) เพื่อสร้าง Iterator สมาชิกเดี่ยว จะถือเป็นสำนวนการเขียนโค้ดที่ชัดเจนและตรงไปตรงมากว่า

นอกจากนี้ การที่ `Option` อิมพลีเมนต์ `IntoIterator` ยังทำให้เราสามารถนำมันไปวนลูปด้วย `for` loop ได้ด้วย ซึ่งมีผลลัพธ์เทียบเท่ากับการเขียน `if let Some(..)` แต่ในบริบททั่วไปส่วนใหญ่ การเลือกใช้ `if let` จะอ่านง่ายและเป็นธรรมชาติกว่า

## ดูเพิ่มเติม

- [`std::iter::once`](https://doc.rust-lang.org/std/iter/fn.once.html) ตัวสร้างอิเทอเรเตอร์ที่ให้สมาชิกเพียงตัวเดียวพอดี เป็นทางเลือกที่อ่านเข้าใจง่ายกว่าการเขียน `Some(foo).into_iter()`
- [`Iterator::filter_map`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.filter_map)
  เมท็อดดัดแปลงของ [`Iterator::map`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.map)
  ที่ออกแบบมาสำหรับฟังก์ชันที่ส่งคืนค่ากลับมาเป็น `Option`
- crate [`ref_slice`](https://crates.io/crates/ref_slice) มีฟังก์ชันสำหรับ
  แปลง `Option` เป็น slice ที่มีสมาชิก 0 หรือ 1 ตัว
- [เอกสารประกอบของ `Option<T>`](https://doc.rust-lang.org/std/option/enum.Option.html)
