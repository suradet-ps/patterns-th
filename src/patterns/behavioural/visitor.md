# Visitor pattern (แพตเทิร์นผู้มาเยือน)

## คำอธิบาย

Visitor pattern ทำหน้าที่ห่อหุ้มอัลกอริทึมที่ต้องเข้าไปดำเนินการกับชุดของออบเจกต์ที่ประกอบด้วยชนิดข้อมูลแตกต่างกัน (heterogeneous collection) ซึ่งเปิดโอกาสให้เราสามารถเขียนอัลกอริทึมที่หลากหลายเพื่อประมวลผลบนชุดข้อมูลเดิมได้ โดยไม่ต้องแก้ไขโครงสร้างข้อมูลหรือพฤติกรรมหลักของออบเจกต์เหล่านั้นเลย

ยิ่งไปกว่านั้น Visitor pattern ยังช่วยแยกตรรกะการท่องผ่านโครงสร้างข้อมูล (traversal) ออกจากการดำเนินการ (operations) ที่กระทำกับแต่ละโหนดข้อมูลอย่างชัดเจน

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

เราสามารถเขียน Visitor ตัวอื่นๆ เพิ่มเติมได้ตามต้องการ เช่น ตัวตรวจสอบชนิดข้อมูล (type checker) โดยไม่ต้องแก้ไขโครงสร้างของข้อมูล AST เลยแม้แต่น้อย

## แรงจูงใจ

Visitor pattern มีประโยชน์อย่างยิ่งในทุกสถานการณ์ที่คุณต้องการนำอัลกอริทึมไปประมวลผลกับข้อมูลที่มีชนิดข้อมูลหลากหลาย (heterogeneous data) ทว่าหากข้อมูลทั้งหมดเป็นชนิดเดียวกัน การใช้ iterator รูปแบบทั่วไปย่อมเพียงพอแล้ว นอกจากนี้ การใช้ออบเจกต์ Visitor (เมื่อเทียบกับแนวทางเชิงฟังก์ชันบริสุทธิ์) ยังเปิดโอกาสให้ตัว Visitor สามารถถือสถานะ (stateful) จึงส่งต่อและแลกเปลี่ยนข้อมูลระหว่างโหนดต่างๆ ได้อย่างสะดวก

## การอภิปราย

ในทางปฏิบัติ เป็นเรื่องปกติที่เมท็อด `visit_*` จะคืนค่าว่าง (`()`) ต่างจากในตัวอย่างข้างต้น ซึ่งในกรณีดังกล่าว เราสามารถแยกโค้ดส่วนการท่องผ่านโครงสร้างข้อมูลออกมา เพื่อนำกลับมาใช้ซ้ำร่วมกันระหว่างอัลกอริทึมต่างๆ ได้ (พร้อมทั้งยังสามารถกำหนดเมท็อดเริ่มต้นที่ไม่ต้องทำอะไรเลย หรือ no-op default methods ได้ด้วย) สำหรับในภาษา Rust วิธีการที่นิยมใช้กันทั่วไปคือการสร้างฟังก์ชัน `walk_*` แยกไว้สำหรับแต่ละชนิดข้อมูล ตัวอย่างเช่น:

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

ในภาษาอื่นๆ (เช่น Java) มักจะมีแบบแผนที่ข้อมูลแต่ละตัวจะมีเมท็อด `accept` เพื่อทำหน้าที่ส่งต่อ Visitor ในลักษณะเดียวกันนี้

## ดูเพิ่มเติม

Visitor pattern เป็นแพตเทิร์นที่พบเห็นได้บ่อยในภาษาเชิงวัตถุ (OO) เกือบทุกภาษา

[บทความบน Wikipedia](https://en.wikipedia.org/wiki/Visitor_pattern)

แพตเทิร์น [Fold](../creational/fold.md) มีลักษณะคล้ายคลึงกับ Visitor แต่จะมุ่งเน้นการสร้างโครงสร้างข้อมูลเวอร์ชันใหม่ขึ้นมาแทนจากการท่องผ่านข้อมูลเดิม
