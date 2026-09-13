# ผู้มาเยือน (Visitor)

## คำอธิบาย

ผู้มาเยือนห่อหุ้มอัลกอริทึมที่ทำงานบนคอลเลกชันของออบเจกต์ต่างชนิดกัน (heterogeneous) ช่วยให้เขียนอัลกอริทึมหลายแบบบนข้อมูลชุดเดียวกันได้โดยไม่ต้องแก้ไขข้อมูล (หรือพฤติกรรมหลักของข้อมูลนั้น)

ยิ่งไปกว่านั้น แพตเทิร์นผู้มาเยือนยังช่วยแยกการท่องไปในคอลเลกชันของออบเจกต์ออกจากการดำเนินการที่ทำกับแต่ละออบเจกต์ได้อีกด้วย

## ตัวอย่าง

```rust,ignore
// The data we will visit
mod ast {
    pub enum Stmt {
        Expr(Expr),
        Let(Name, Expr),
    }

    pub struct Name {
        value: String,
    }

    pub enum Expr {
        IntLit(i64),
        Add(Box<Expr>, Box<Expr>),
        Sub(Box<Expr>, Box<Expr>),
    }
}

// The abstract visitor
mod visit {
    use ast::*;

    pub trait Visitor<T> {
        fn visit_name(&mut self, n: &Name) -> T;
        fn visit_stmt(&mut self, s: &Stmt) -> T;
        fn visit_expr(&mut self, e: &Expr) -> T;
    }
}

use ast::*;
use visit::*;

// An example concrete implementation - walks the AST interpreting it as code.
struct Interpreter;
impl Visitor<i64> for Interpreter {
    fn visit_name(&mut self, n: &Name) -> i64 {
        panic!()
    }
    fn visit_stmt(&mut self, s: &Stmt) -> i64 {
        match *s {
            Stmt::Expr(ref e) => self.visit_expr(e),
            Stmt::Let(..) => unimplemented!(),
        }
    }

    fn visit_expr(&mut self, e: &Expr) -> i64 {
        match *e {
            Expr::IntLit(n) => n,
            Expr::Add(ref lhs, ref rhs) => self.visit_expr(lhs) + self.visit_expr(rhs),
            Expr::Sub(ref lhs, ref rhs) => self.visit_expr(lhs) - self.visit_expr(rhs),
        }
    }
}
```

เราสามารถอิมพลีเมนต์ผู้มาเยือนเพิ่มเติมได้ เช่น ตัวตรวจสอบชนิด โดยไม่ต้องแก้ไขข้อมูล AST

## แรงจูงใจ

แพตเทิร์นผู้มาเยือนมีประโยชน์ทุกที่ที่คุณต้องการนำอัลกอริทึมไปใช้กับข้อมูลต่างชนิดกัน หากข้อมูลเป็นชนิดเดียวกันหมด คุณใช้อิเทอเรเตอร์ได้ การใช้ผู้มาเยือนเป็นออบเจกต์ (แทนแนวทางเชิงฟังก์ชัน) ช่วยให้ผู้มาเยือนเก็บสถานะได้ จึงสื่อสารข้อมูลระหว่างโหนดต่างๆ ได้

## การอภิปราย

เป็นเรื่องปกติที่เมท็อด `visit_*` จะคืนค่า void (ต่างจากในตัวอย่าง) ในกรณีนั้นเราสามารถแยกโค้ดการท่องไปออกมาและแบ่งปันระหว่างอัลกอริทึมต่างๆ ได้ (และยังให้เมท็อด default แบบไม่ทำอะไรได้ด้วย) ใน Rust วิธีที่พบบ่อยคือการให้ฟังก์ชัน `walk_*` สำหรับแต่ละข้อมูล ตัวอย่างเช่น

```rust,ignore
pub fn walk_expr(visitor: &mut Visitor, e: &Expr) {
    match *e {
        Expr::IntLit(_) => {}
        Expr::Add(ref lhs, ref rhs) => {
            visitor.visit_expr(lhs);
            visitor.visit_expr(rhs);
        }
        Expr::Sub(ref lhs, ref rhs) => {
            visitor.visit_expr(lhs);
            visitor.visit_expr(rhs);
        }
    }
}
```

ในภาษาอื่น (เช่น Java) เป็นเรื่องปกติที่ข้อมูลจะมีเมท็อด `accept` ซึ่งทำหน้าที่เดียวกัน

## ดูเพิ่มเติม

แพตเทิร์นผู้มาเยือนเป็นแพตเทิร์นที่พบบ่อยในภาษา OO ส่วนใหญ่

[บทความวิกิพีเดีย](https://en.wikipedia.org/wiki/Visitor_pattern)

แพตเทิร์น [โฟลด์](../creational/fold.md) คล้ายกับผู้มาเยือน แต่สร้างข้อมูลที่ถูกเยี่ยมชมเวอร์ชันใหม่ขึ้นมาแทน
