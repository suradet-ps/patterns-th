# Interpreter pattern (แพตเทิร์นอินเทอร์พรีเตอร์)

## คำอธิบาย

หากโจทย์ปัญหาหนึ่งเกิดขึ้นซ้ำบ่อยครั้ง และต้องอาศัยขั้นตอนการแก้ปัญหาที่ยาวและซ้ำซาก เราสามารถแปลงรูปแบบของโจทย์ปัญหานั้นให้อยู่ในรูปของภาษาเชิงสัญลักษณ์ที่เรียบง่ายภาษาหนึ่ง แล้วสร้างออบเจกต์อินเทอร์พรีเตอร์ (interpreter) ขึ้นมาเพื่อแก้ปัญหาดังกล่าวด้วยการตีความประโยคที่เขียนขึ้นในภาษานั้น

โดยทั่วไป สำหรับปัญหาใดๆ ก็ตาม เราจะกำหนดองค์ประกอบดังนี้:

- [ภาษาเฉพาะโดเมน (Domain-Specific Language: DSL)](https://en.wikipedia.org/wiki/Domain-specific_language)
- ไวยากรณ์ (grammar) สำหรับภาษานั้น
- อินเทอร์พรีเตอร์ที่ทำหน้าที่ตีความและประมวลผลคำสั่งเพื่อแก้ปัญหา

## แรงจูงใจ

เป้าหมายของเราคือการแปลงนิพจน์ทางคณิตศาสตร์แบบเรียบง่ายให้อยู่ในรูปของ postfix (หรือที่เรียกว่า
[สัญกรณ์โพแลนด์แบบย้อนกลับ / Reverse Polish notation](https://en.wikipedia.org/wiki/Reverse_Polish_notation))
เพื่อความเรียบง่าย นิพจน์ของเราจะประกอบด้วยตัวเลขโดด 10 ตัว คือ `0`, ..., `9` และตัวดำเนินการ 2 ชนิดคือ `+` กับ `-` ตัวอย่างเช่น นิพจน์ `2 + 4` จะถูกแปลงเป็น
`2 4 +`

## ไวยากรณ์แบบไม่มีบริบท (Context Free Grammar) สำหรับปัญหาของเรา

โจทย์ของเราคือการแปลงนิพจน์แบบ infix ให้เป็นนิพจน์แบบ postfix เรามานิยามไวยากรณ์แบบไม่มีบริบท (Context-Free Grammar: CFG) สำหรับชุดนิพจน์ infix ที่ประกอบด้วย `0`, ..., `9`, `+` และ `-` โดยมีข้อกำหนดดังนี้:

- สัญลักษณ์ปลายทาง (Terminal symbols): `0`, `...`, `9`, `+`, `-`
- สัญลักษณ์ไม่ปลายทาง (Non-terminal symbols): `exp`, `term`
- สัญลักษณ์เริ่มต้น (Start symbol): `exp`
- และมีกฎการแปลง (Production rules) ดังนี้

```ignore
exp -> exp + term
exp -> exp - term
exp -> term
term -> 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
```

**ข้อสังเกต:** ไวยากรณ์นี้อาจต้องนำไปแปลงรูปต่อยอดขึ้นอยู่กับรูปแบบการประมวลผล เช่น เราอาจจำเป็นต้องขจัด left recursion ออกไป สำหรับรายละเอียดเชิงลึกสามารถศึกษาเพิ่มเติมได้จากหนังสือ
[Compilers: Principles,Techniques, and Tools](https://en.wikipedia.org/wiki/Compilers:_Principles,_Techniques,_and_Tools)
(หรือที่รู้จักกันอย่างแพร่หลายในชื่อ "Dragon Book")

## ทางออก

ในที่นี้ เราจะเลือกอิมพลีเมนต์ recursive descent parser แบบตรงไปตรงมา และเพื่อความกระชับ โค้ดจะหยุดทำงานทันที (panic) เมื่อพบข้อผิดพลาดทางไวยากรณ์ในนิพจน์ (ตัวอย่างเช่น `2-34` หรือ `2+5-` จะถือว่าผิดตามโครงสร้างไวยากรณ์ที่นิยามไว้)

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

หลายคนอาจมีความเข้าใจคลาดเคลื่อนว่า Interpreter pattern เป็นเรื่องของการออกแบบไวยากรณ์สำหรับภาษาเชิงรูปนัย (formal languages) และการสร้างตัววิเคราะห์ไวยากรณ์ (parser) เท่านั้น แต่แท้จริงแล้ว แพตเทิร์นนี้หมายรวมถึงการถ่ายทอดปัญหาให้อยู่ในรูปภาษาที่เฉพาะเจาะจง และสร้างฟังก์ชัน/คลาส/struct ขึ้นมารับผิดชอบการประมวลผลคำสั่งเหล่านั้น นอกจากนี้ ในภาษา Rust ยังมีฟีเจอร์อันทรงพลังอย่าง `macro_rules!` ซึ่งช่วยให้เราสามารถกำหนดไวยากรณ์พิเศษและกฎการขยายโค้ด (macro expansion) ลงในซอร์สโค้ดได้โดยตรง

ในตัวอย่างด้านล่างนี้ เราได้สร้าง `macro_rules!` แบบเรียบง่ายเพื่อคำนวณ
[ระยะทางแบบยูคลิด (Euclidean distance/length)](https://en.wikipedia.org/wiki/Euclidean_distance) ของเวกเตอร์ขนาด `n` มิติ ซึ่งการเขียนโค้ดในรูปแบบ `norm!(x, 1, 2)` นั้นทั้งสื่อความหมายได้ชัดเจนและมีประสิทธิภาพเหนือกว่าการนำ `x, 1, 2` ไปแพ็กลงใน `Vec` เพื่อส่งให้ฟังก์ชันภายนอกคำนวณอย่างเห็นได้ชัด

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

- [Interpreter pattern](https://en.wikipedia.org/wiki/Interpreter_pattern)
- [Context free grammar](https://en.wikipedia.org/wiki/Context-free_grammar)
- [macro_rules!](https://doc.rust-lang.org/rust-by-example/macros.html)
