# Command pattern (แพตเทิร์นคำสั่ง)

## คำอธิบาย

แนวคิดพื้นฐานของ Command pattern คือการแยกการกระทำ (action) ออกมาเป็นออบเจกต์เฉพาะตัว แล้วส่งต่อไปยังส่วนอื่นๆ ในฐานะพารามิเตอร์

## แรงจูงใจ

สมมติว่าเรามีลำดับของการกระทำหรือทรานแซกชันที่ถูกห่อหุ้มไว้ในรูปของออบเจกต์ เราต้องการให้การกระทำหรือคำสั่งเหล่านี้สามารถนำไปประมวลผลหรือเรียกใช้งานในภายหลังตามลำดับที่กำหนดไว้ ณ เวลาที่เหมาะสม นอกจากนี้ คำสั่งเหล่านี้อาจถูกกระตุ้นให้ทำงานจากเหตุการณ์ (event) บางอย่าง เช่น เมื่อผู้ใช้กดปุ่ม หรือเมื่อมีแพ็กเก็ตข้อมูลส่งมาถึง ยิ่งไปกว่านั้น คำสั่งเหล่านี้อาจถูกออกแบบให้สามารถย้อนกลับ (undo) ได้ ซึ่งมีประโยชน์อย่างยิ่งสำหรับโปรแกรมประเภท Text Editor หรือการบันทึกประวัติการทำงาน (log) ของคำสั่งต่างๆ เพื่อนำกลับมาทำซ้ำใหม่ในภายหลังหากระบบเกิดความเสียหาย

## ตัวอย่าง

กำหนดการทำงานของฐานข้อมูลขึ้นมา 2 คำสั่ง ได้แก่ `create table` และ `add field` โดยคำสั่งแต่ละตัวจะรู้วิธียกเลิกการทำงานของตัวเอง (undo) เช่น `drop table` และ `remove field` ตามลำดับ เมื่อผู้ใช้เรียกใช้งาน migration ของฐานข้อมูล คำสั่งแต่ละตัวจะถูกประมวลผลตามลำดับที่วางไว้ และเมื่อผู้ใช้สั่ง rollback คำสั่งทั้งชุดจะถูกเรียกทำงานย้อนกลับในลำดับตรงกันข้าม

## แนวทาง: ใช้ trait object

เรานิยาม trait ร่วมที่ห่อหุ้มคำสั่งของเราด้วยการดำเนินการ 2 ประการ ได้แก่ `execute` และ `rollback` โดยโครงสร้างข้อมูล (`struct`) ของคำสั่งทั้งหมดจะต้องนำ trait นี้ไปอิมพลีเมนต์

```rust
pub trait Migration {
    fn execute(&self) -> &str;
    fn rollback(&self) -> &str;
}

pub struct CreateTable;
impl Migration for CreateTable {
    fn execute(&self) -> &str {
        "create table"
    }
    fn rollback(&self) -> &str {
        "drop table"
    }
}

pub struct AddField;
impl Migration for AddField {
    fn execute(&self) -> &str {
        "add field"
    }
    fn rollback(&self) -> &str {
        "remove field"
    }
}

struct Schema {
    commands: Vec<Box<dyn Migration>>,
}

impl Schema {
    fn new() -> Self {
        Self { commands: vec![] }
    }

    fn add_migration(&mut self, cmd: Box<dyn Migration>) {
        self.commands.push(cmd);
    }

    fn execute(&self) -> Vec<&str> {
        self.commands.iter().map(|cmd| cmd.execute()).collect()
    }
    fn rollback(&self) -> Vec<&str> {
        self.commands
            .iter()
            .rev() // reverse iterator's direction
            .map(|cmd| cmd.rollback())
            .collect()
    }
}

fn main() {
    let mut schema = Schema::new();

    let cmd = Box::new(CreateTable);
    schema.add_migration(cmd);
    let cmd = Box::new(AddField);
    schema.add_migration(cmd);

    assert_eq!(vec!["create table", "add field"], schema.execute());
    assert_eq!(vec!["remove field", "drop table"], schema.rollback());
}
```

## แนวทาง: ใช้ function pointer

เราอาจเลือกใช้แนวทางอื่นโดยเขียนคำสั่งแต่ละตัวเป็นฟังก์ชันแยกต่างหาก แล้วจัดเก็บพอยน์เตอร์ของฟังก์ชัน (function pointer) ไว้สำหรับเรียกทำงานในภายหลัง และเนื่องจาก function pointer นำทั้ง 3 trait ได้แก่ `Fn`, `FnMut` และ `FnOnce` ไปใช้งานโดยอัตโนมัติ เราจึงสามารถส่งและจัดเก็บ closure แทน function pointer ได้เช่นเดียวกัน

```rust
type FnPtr = fn() -> String;
struct Command {
    execute: FnPtr,
    rollback: FnPtr,
}

struct Schema {
    commands: Vec<Command>,
}

impl Schema {
    fn new() -> Self {
        Self { commands: vec![] }
    }
    fn add_migration(&mut self, execute: FnPtr, rollback: FnPtr) {
        self.commands.push(Command { execute, rollback });
    }
    fn execute(&self) -> Vec<String> {
        self.commands.iter().map(|cmd| (cmd.execute)()).collect()
    }
    fn rollback(&self) -> Vec<String> {
        self.commands
            .iter()
            .rev()
            .map(|cmd| (cmd.rollback)())
            .collect()
    }
}

fn add_field() -> String {
    "add field".to_string()
}

fn remove_field() -> String {
    "remove field".to_string()
}

fn main() {
    let mut schema = Schema::new();
    schema.add_migration(|| "create table".to_string(), || "drop table".to_string());
    schema.add_migration(add_field, remove_field);
    assert_eq!(vec!["create table", "add field"], schema.execute());
    assert_eq!(vec!["remove field", "drop table"], schema.rollback());
}
```

## แนวทาง: ใช้ `Fn` trait object

และแนวทางสุดท้าย แทนที่จะต้องนิยาม trait กลางขึ้นมา เราสามารถจัดเก็บคำสั่งแต่ละตัวที่นำ trait `Fn` ไปใช้งานแยกกันไว้ในเวกเตอร์ได้โดยตรง

```rust
type Migration<'a> = Box<dyn Fn() -> &'a str>;

struct Schema<'a> {
    executes: Vec<Migration<'a>>,
    rollbacks: Vec<Migration<'a>>,
}

impl<'a> Schema<'a> {
    fn new() -> Self {
        Self {
            executes: vec![],
            rollbacks: vec![],
        }
    }
    fn add_migration<E, R>(&mut self, execute: E, rollback: R)
    where
        E: Fn() -> &'a str + 'static,
        R: Fn() -> &'a str + 'static,
    {
        self.executes.push(Box::new(execute));
        self.rollbacks.push(Box::new(rollback));
    }
    fn execute(&self) -> Vec<&str> {
        self.executes.iter().map(|cmd| cmd()).collect()
    }
    fn rollback(&self) -> Vec<&str> {
        self.rollbacks.iter().rev().map(|cmd| cmd()).collect()
    }
}

fn add_field() -> &'static str {
    "add field"
}

fn remove_field() -> &'static str {
    "remove field"
}

fn main() {
    let mut schema = Schema::new();
    schema.add_migration(|| "create table", || "drop table");
    schema.add_migration(add_field, remove_field);
    assert_eq!(vec!["create table", "add field"], schema.execute());
    assert_eq!(vec!["remove field", "drop table"], schema.rollback());
}
```

## การอภิปราย

หากคำสั่งของเรามีขนาดเล็กและสามารถนิยามเป็นฟังก์ชันธรรมดาหรือส่งเข้ามาในรูปของ closure ได้ การเลือกใช้ function pointer มักเป็นทางเลือกที่เหมาะสมกว่า เนื่องจากไม่มี overhead จาก dynamic dispatch แต่หากคำสั่งของเรามีโครงสร้างที่ซับซ้อน เป็น struct เต็มรูปแบบที่มีฟังก์ชันและข้อมูลภายในหลายตัวแยกเป็นโมดูลชัดเจน การใช้ trait object ย่อมเหมาะสมและเข้ากับการจัดโครงสร้างมากกว่า กรณีการใช้งานจริงในลักษณะนี้สามารถพบได้ในเฟรมเวิร์ก [`actix`](https://actix.rs/) ซึ่งใช้ประโยชน์จาก trait object ในการลงทะเบียน handler function สำหรับ routing ต่างๆ ส่วนกรณีที่ใช้ `Fn` trait object เราสามารถสร้างและใช้งานคำสั่งได้ในลักษณะเดียวกับแนวทางของ function pointer

ในด้านประสิทธิภาพ ย่อมมีข้อแลกเปลี่ยน (trade-off) ระหว่างความเร็วในการทำงานกับความเรียบง่ายและการจัดโครงสร้างโค้ดเสมอ โดย static dispatch จะให้ประสิทธิภาพการทำงานที่รวดเร็วกว่า ขณะที่ dynamic dispatch มอบความยืดหยุ่นสูงเมื่อเราต้องการออกแบบโครงสร้างของแอปพลิเคชัน

## ดูเพิ่มเติม

- [Command pattern](https://en.wikipedia.org/wiki/Command_pattern)

- [Another example for the `command` pattern](https://web.archive.org/web/20210223131236/https://chercher.tech/rust/command-design-pattern-rust)
