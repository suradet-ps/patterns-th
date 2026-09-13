# คำสั่ง (Command)

## คำอธิบาย

แนวคิดพื้นฐานของแพตเทิร์นคำสั่งคือการแยกการกระทำออกมาเป็นออบเจกต์ของตัวเองแล้วส่งเป็นพารามิเตอร์

## แรงจูงใจ

สมมติว่าเรามีลำดับของการกระทำหรือทรานแซกชันที่ห่อหุ้มเป็นออบเจกต์ เราต้องการให้การกระทำหรือคำสั่งเหล่านี้ถูกเรียกใช้หรือถูกเรียกในลำดับใดลำดับหนึ่งในภายหลัง ณ เวลาที่ต่างออกไป คำสั่งเหล่านี้อาจถูกกระตุ้นจากเหตุการณ์บางอย่างก็ได้ ตัวอย่างเช่น เมื่อผู้ใช้กดปุ่ม หรือเมื่อแพ็กเก็ตข้อมูลมาถึง นอกจากนี้ คำสั่งเหล่านี้อาจสามารถย้อนกลับ (undo) ได้ ซึ่งอาจมีประโยชน์สำหรับการดำเนินการของโปรแกรมแก้ไขข้อความ เราอาจต้องการเก็บบันทึกของคำสั่งที่ถูกเรียกใช้ เพื่อให้สามารถนำการเปลี่ยนแปลงกลับมาใช้ใหม่ได้ในภายหลังหากระบบล่ม

## ตัวอย่าง

นิยามการดำเนินการฐานข้อมูลสองอย่างคือ `create table` และ `add field` การดำเนินการแต่ละอย่างเป็นคำสั่งที่รู้วิธี undo ตัวเอง เช่น `drop table` และ `remove field` เมื่อผู้ใช้เรียกการดำเนินการ migration ของฐานข้อมูล คำสั่งแต่ละตัวจะถูกเรียกตามลำดับที่กำหนดไว้ และเมื่อผู้ใช้เรียกการดำเนินการ rollback คำสั่งทั้งชุดจะถูกเรียกในลำดับย้อนกลับ

## แนวทาง: ใช้ trait object

เรานิยาม trait ร่วมที่ห่อหุ้มคำสั่งของเราด้วยการดำเนินการสองอย่างคือ `execute` และ `rollback` ทุก `struct` ของคำสั่งต้องอิมพลีเมนต์ trait นี้

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

## แนวทาง: ใช้พอยน์เตอร์ฟังก์ชัน

เราอาจใช้แนวทางอื่นโดยสร้างคำสั่งแต่ละตัวเป็นฟังก์ชันต่างหาก แล้วเก็บพอยน์เตอร์ฟังก์ชันไว้เรียกฟังก์ชันเหล่านั้นในภายหลัง ณ เวลาที่ต่างออกไป เนื่องจากพอยน์เตอร์ฟังก์ชันอิมพลีเมนต์ทั้งสาม trait `Fn`, `FnMut` และ `FnOnce` เราจึงส่งและเก็บโคลเชอร์แทนพอยน์เตอร์ฟังก์ชันได้เช่นกัน

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

สุดท้าย แทนที่จะนิยาม trait คำสั่งร่วม เราอาจเก็บคำสั่งแต่ละตัวที่อิมพลีเมนต์ trait `Fn` แยกกันในเวกเตอร์

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

หากคำสั่งของเรามีขนาดเล็กและอาจนิยามเป็นฟังก์ชันหรือส่งเป็นโคลเชอร์ได้ การใช้พอยน์เตอร์ฟังก์ชันอาจน่าสนใจกว่าเพราะไม่ต้องใช้ไดนามิกดิสแพตช์ แต่หากคำสั่งของเราเป็น struct เต็มรูปแบบที่มีฟังก์ชันและตัวแปรมากมายนิยามเป็นโมดูลแยก การใช้ trait object จะเหมาะสมกว่า ตัวอย่างการนำไปใช้พบได้ใน [`actix`](https://actix.rs/) ซึ่งใช้ trait object เมื่อลงทะเบียนฟังก์ชันตัวจัดการสำหรับเส้นทาง (route) ในกรณีที่ใช้ `Fn` trait object เราสร้างและใช้คำสั่งได้ในแบบเดียวกับที่ใช้ในกรณีพอยน์เตอร์ฟังก์ชัน

ในแง่ประสิทธิภาพ มีการแลกเปลี่ยนระหว่างประสิทธิภาพกับความเรียบง่ายและการจัดระเบียบโค้ดเสมอ สแตติกดิสแพตช์ให้ประสิทธิภาพที่เร็วกว่า ขณะที่ไดนามิกดิสแพตช์ให้ความยืดหยุ่นในการจัดโครงสร้างแอปพลิเคชันของเรา

## ดูเพิ่มเติม

- [แพตเทิร์นคำสั่ง](https://en.wikipedia.org/wiki/Command_pattern)

- [อีกตัวอย่างของแพตเทิร์น `command`](https://web.archive.org/web/20210223131236/https://chercher.tech/rust/command-design-pattern-rust)
