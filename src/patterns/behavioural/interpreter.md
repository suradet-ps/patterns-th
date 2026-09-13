# อินเทอร์พรีเตอร์

## คำอธิบาย

หากปัญหาหนึ่งเกิดขึ้นบ่อยมากและต้องใช้ขั้นตอนยาวๆ ซ้ำๆ ในการแก้ อินสแตนซ์ของปัญหานั้นอาจถูกแสดงในภาษาง่ายๆ ภาษาเดียว แล้วออบเจกต์อินเทอร์พรีเตอร์ก็แก้ปัญหาได้ด้วยการตีความประโยคที่เขียนในภาษาง่ายๆ นั้น

โดยพื้นฐานแล้ว สำหรับปัญหาใดๆ เรานิยาม:

- [ภาษาจำเพาะโดเมน](https://en.wikipedia.org/wiki/Domain-specific_language)
- ไวยากรณ์ของภาษานี้
- อินเทอร์พรีเตอร์ที่แก้ปัญหานั้น

## แรงจูงใจ

เป้าหมายของเราคือแปลนิพจน์คณิตศาสตร์ง่ายๆ ให้เป็นนิพจน์ postfix (หรือ
[สัญกรณ์โพสต์ฟิกซ์ย้อนกลับ / Reverse Polish notation](https://en.wikipedia.org/wiki/Reverse_Polish_notation))
เพื่อความง่าย นิพจน์ของเราประกอบด้วยเลขสิบตัว `0`, ..., `9` และการดำเนินการสองอย่าง `+`, `-` ตัวอย่างเช่น นิพจน์ `2 + 4` ถูกแปลเป็น
`2 4 +`

## ไวยากรณ์แบบไม่มีบริบท (Context Free Grammar) สำหรับปัญหาของเรา

งานของเราคือแปลนิพจน์ infix เป็นนิพจน์ postfix มากำหนดไวยากรณ์แบบไม่มีบริบทสำหรับชุดนิพจน์ infix บน `0`, ..., `9`, `+` และ `-` โดยที่:

- สัญลักษณ์ปลายทาง (Terminal symbols): `0`, `...`, `9`, `+`, `-`
- สัญลักษณ์ไม่ปลายทาง (Non-terminal symbols): `exp`, `term`
- สัญลักษณ์เริ่มต้นคือ `exp`
- และกฎการผลิต (production rules) มีดังนี้

```ignore
exp -> exp + term
exp -> exp - term
exp -> term
term -> 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
```

**หมายเหตุ:** ไวยากรณ์นี้ควรถูกแปลงต่อขึ้นอยู่กับว่าเราจะนำมันไปทำอะไร ตัวอย่างเช่น เราอาจต้องกำจัดการเรียกซ้ำทางซ้าย (left recursion) ออก สำหรับรายละเอียดเพิ่มเติมโปรดดู
[Compilers: Principles,Techniques, and Tools](https://en.wikipedia.org/wiki/Compilers:_Principles,_Techniques,_and_Tools)
(หรือที่รู้จักในชื่อ Dragon Book)

## ทางออก

เราเพียงอิมพลีเมนต์ recursive descent parser เพื่อความง่าย โค้ดจะ panic เมื่อนิพจน์ผิดไวยากรณ์ (ตัวอย่างเช่น `2-34` หรือ `2+5-` ถือว่าผิดตามนิยามไวยากรณ์)

```rust
pub struct Interpreter<'a> {
    it: std::str::Chars<'a>,
}

impl<'a> Interpreter<'a> {
    pub fn new(infix: &'a str) -> Self {
        Self { it: infix.chars() }
    }

    fn next_char(&mut self) -> Option<char> {
        self.it.next()
    }

    pub fn interpret(&mut self, out: &mut String) {
        self.term(out);

        while let Some(op) = self.next_char() {
            if op == '+' || op == '-' {
                self.term(out);
                out.push(op);
            } else {
                panic!("Unexpected symbol '{op}'");
            }
        }
    }

    fn term(&mut self, out: &mut String) {
        match self.next_char() {
            Some(ch) if ch.is_digit(10) => out.push(ch),
            Some(ch) => panic!("Unexpected symbol '{ch}'"),
            None => panic!("Unexpected end of string"),
        }
    }
}

pub fn main() {
    let mut intr = Interpreter::new("2+3");
    let mut postfix = String::new();
    intr.interpret(&mut postfix);
    assert_eq!(postfix, "23+");

    intr = Interpreter::new("1-2+3-4");
    postfix.clear();
    intr.interpret(&mut postfix);
    assert_eq!(postfix, "12-3+4-");
}
```

## การอภิปราย

อาจมีความเข้าใจผิดว่าแพตเทิร์นอินเทอร์พรีเตอร์เป็นเรื่องเกี่ยวกับการออกแบบไวยากรณ์สำหรับภาษารูปนัยและการอิมพลีเมนต์ parser สำหรับไวยากรณ์เหล่านั้น อันที่จริง แพตเทิร์นนี้เป็นเรื่องเกี่ยวกับการแสดงอินสแตนซ์ของปัญหาในแบบที่เฉพาะเจาะจงขึ้น และอิมพลีเมนต์ฟังก์ชัน/คลาส/struct ที่แก้ปัญหานั้น ภาษา Rust มี `macro_rules!` ที่ช่วยให้เรานิยามไวยากรณ์พิเศษและกฎว่าขยายไวยากรณ์นั้นเป็นซอร์สโค้ดอย่างไร

ในตัวอย่างต่อไปนี้ เราสร้าง `macro_rules!` ง่ายๆ ที่คำนวณ
[ความยาวแบบยูคลิด (Euclidean length)](https://en.wikipedia.org/wiki/Euclidean_distance) ของเวกเตอร์ `n` มิติ การเขียน `norm!(x,1,2)` อาจแสดงออกได้ง่ายกว่าและมีประสิทธิภาพกว่าการแพ็ก `x,1,2` ลงใน `Vec` แล้วเรียกฟังก์ชันที่คำนวณความยาว

```rust
macro_rules! norm {
    ($($element:expr),*) => {
        {
            let mut n = 0.0;
            $(
                n += ($element as f64)*($element as f64);
            )*
            n.sqrt()
        }
    };
}

fn main() {
    let x = -3f64;
    let y = 4f64;

    assert_eq!(3f64, norm!(x));
    assert_eq!(5f64, norm!(x, y));
    assert_eq!(0f64, norm!(0, 0, 0));
    assert_eq!(1f64, norm!(0.5, -0.5, 0.5, -0.5));
}
```

## ดูเพิ่มเติม

- [แพตเทิร์นอินเทอร์พรีเตอร์](https://en.wikipedia.org/wiki/Interpreter_pattern)
- [ไวยากรณ์แบบไม่มีบริบท](https://en.wikipedia.org/wiki/Context-free_grammar)
- [macro_rules!](https://doc.rust-lang.org/rust-by-example/macros.html)
