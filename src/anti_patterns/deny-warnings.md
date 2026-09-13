# `#![deny(warnings)]`

## คำอธิบาย

ผู้เขียนครีตที่หวังดีต้องการให้แน่ใจว่าโค้ดของตนบิลด์ได้โดยไม่มีคำเตือน จึงใส่แอตทริบิวต์ที่รากของครีตดังนี้:

## ตัวอย่าง

```rust
#![deny(warnings)]

// All is well.
```

## ข้อดี

สั้น และจะหยุดการบิลด์ทันทีหากมีอะไรผิดปกติ

## ข้อเสีย

การไม่อนุญาตให้คอมไพเลอร์บิลด์พร้อมคำเตือน เท่ากับผู้เขียนครีตเลือกที่จะไม่รับความเสถียรอันเลื่องชื่อของ Rust บางครั้งฟีเจอร์ใหม่หรือคุณสมบัติเก่าที่ไม่ดีจำเป็นต้องเปลี่ยนวิธีทำสิ่งต่างๆ จึงมีการเขียน lint ที่ `warn` เป็นช่วงผ่อนผันก่อนจะเปลี่ยนเป็น `deny`

ตัวอย่างเช่น มีการค้นพบว่าชนิดข้อมูลหนึ่งสามารถมี `impl` สองอันที่มีเมท็อดเดียวกันได้ เรื่องนี้ถูกตัดสินว่าเป็นความคิดที่ไม่ดี แต่เพื่อให้การเปลี่ยนผ่านราบรื่น จึงมีการเพิ่ม lint `overlapping-inherent-impls` เพื่อเตือนผู้ที่สะดุดกับข้อเท็จจริงนี้ ก่อนที่มันจะกลายเป็นข้อผิดพลาดแบบแข็ง (hard error) ในรีลีสในอนาคต

นอกจากนี้ บางครั้ง API ก็ถูกทำให้เลิกใช้ (deprecate) การใช้งานจึงเปล่งคำเตือนในจุดที่เคยไม่มี

ปัจจัยทั้งหมดนี้อาจทำให้การบิลด์พังได้ทุกเมื่อที่มีอะไรเปลี่ยนแปลง

ยิ่งไปกว่านั้น ครีตที่ให้ lint เพิ่มเติม (เช่น [rust-clippy]) จะใช้งานไม่ได้อีกต่อไปเว้นแต่จะลบแอตทริบิวต์ออก ซึ่งบรรเทาได้ด้วย [--cap-lints] อาร์กิวเมนต์บรรทัดคำสั่ง `--cap-lints=warn` จะเปลี่ยนข้อผิดพลาดจาก lint ที่เป็น `deny` ทั้งหมดให้กลายเป็นคำเตือน

## ทางเลือกอื่น

มีสองวิธีจัดการปัญหานี้: วิธีแรก เราแยกการตั้งค่าการบิลด์ออกจากโค้ด และวิธีที่สอง เราระบุชื่อ lint ที่ต้องการ `deny` อย่างชัดเจน

บรรทัดคำสั่งต่อไปนี้จะบิลด์โดยตั้งคำเตือนทั้งหมดเป็น `deny`:

`RUSTFLAGS="-D warnings" cargo build`

นักพัฒนาแต่ละคนสามารถทำเช่นนี้ได้ (หรือตั้งในเครื่องมือ CI อย่าง Travis แต่พึงจำว่าอาจทำให้การบิลด์พังเมื่อมีอะไรเปลี่ยนแปลง) โดยไม่ต้องแก้โค้ด

อีกทางหนึ่ง เราระบุ lint ที่ต้องการ `deny` ในโค้ดได้ นี่คือรายการ lint ประเภทคำเตือนที่ (หวังว่า) ปลอดภัยที่จะ deny (ณ rustc
1.48.0):

```rust,ignore
#![deny(
    bad_style,
    const_err,
    dead_code,
    improper_ctypes,
    non_shorthand_field_patterns,
    no_mangle_generic_items,
    overflowing_literals,
    path_statements,
    patterns_in_fns_without_body,
    private_in_public,
    unconditional_recursion,
    unused,
    unused_allocation,
    unused_comparisons,
    unused_parens,
    while_true
)]
```

นอกจากนี้ lint ที่ถูก `allow` ไว้ต่อไปนี้อาจเป็นความคิดที่ดีที่จะ `deny`:

```rust,ignore
#![deny(
    missing_debug_implementations,
    missing_docs,
    trivial_casts,
    trivial_numeric_casts,
    unused_extern_crates,
    unused_import_braces,
    unused_qualifications,
    unused_results
)]
```

บางคนอาจต้องการเพิ่ม `missing-copy-implementations` เข้าในรายการด้วย

พึงสังเกตว่าเราไม่ได้เพิ่ม lint `deprecated` อย่างชัดเจน เพราะค่อนข้างแน่นอนว่าในอนาคตจะมี API ที่เลิกใช้เพิ่มขึ้นอีก

## ดูเพิ่มเติม

- [รวม lint ทั้งหมดของ clippy](https://rust-lang.github.io/rust-clippy/master)
- เอกสารประกอบของ [deprecate attribute]
- พิมพ์ `rustc -W help` เพื่อดูรายการ lint บนเครื่องของคุณ และพิมพ์
  `rustc --help` เพื่อดูรายการตัวเลือกทั่วไป
- [rust-clippy] เป็นชุด lint สำหรับเขียนโค้ด Rust ให้ดีขึ้น

[rust-clippy]: https://github.com/rust-lang/rust-clippy
[deprecate attribute]: https://doc.rust-lang.org/reference/attributes.html#deprecation
[--cap-lints]: https://doc.rust-lang.org/rustc/lints/levels.html#capping-lints
