# การเริ่มต้นเอกสารประกอบอย่างง่าย

## คำอธิบาย

หาก struct ของคุณมีขั้นตอนการกำหนดค่าเริ่มต้น (Initialization) ที่ซับซ้อนหรือต้องเขียนโค้ดยืดยาวเมื่อเขียนตัวอย่างในเอกสารประกอบ (Rustdoc) การห่อโค้ดตัวอย่างนั้นไว้ในฟังก์ชันตัวช่วยที่ประกาศรับ struct เป็นอาร์กิวเมนต์ จะช่วยประหยัดเวลาและลดโค้ดซ้ำซ้อนได้อย่างมาก

## ที่มาและเหตุผล

ในบางครั้ง struct อาจมีฟิลด์หรือพารามิเตอร์จำนวนมากที่ซับซ้อน และมีเมท็อดหลายตัวที่จำเป็นต้องเขียนตัวอย่างการใช้งานกำกับไว้ในเอกสารทุกเมท็อด

ตัวอย่างเช่น:

````rust,ignore
struct Connection {
    name: String,
    stream: TcpStream,
}

impl Connection {
    /// Sends a request over the connection.
    ///
    /// # Example
    /// ```no_run
    /// # // Boilerplate are required to get an example working.
    /// # let stream = TcpStream::connect("127.0.0.1:34254");
    /// # let connection = Connection { name: "foo".to_owned(), stream };
    /// # let request = Request::new("RequestId", RequestType::Get, "payload");
    /// let response = connection.send_request(request);
    /// assert!(response.is_ok());
    /// ```
    fn send_request(&self, request: Request) -> Result<Status, SendErr> {
        // ...
    }

    /// Oh no, all that boilerplate needs to be repeated here!
    fn check_status(&self) -> Status {
        // ...
    }
}
````

## ตัวอย่าง

แทนที่จะต้องพิมพ์โค้ด boilerplate ทั้งหมดซ้ำๆ เพื่อสร้าง `Connection` และ `Request` การสร้างฟังก์ชันตัวช่วยห่อหุ้มที่รับค่าเหล่านั้นเข้ามาเป็นพารามิเตอร์จะทำได้ง่ายและสะอาดกว่ามาก:

````rust,ignore
struct Connection {
    name: String,
    stream: TcpStream,
}

impl Connection {
    /// Sends a request over the connection.
    ///
    /// # Example
    /// ```
    /// # fn call_send(connection: Connection, request: Request) {
    /// let response = connection.send_request(request);
    /// assert!(response.is_ok());
    /// # }
    /// ```
    fn send_request(&self, request: Request) -> Result<Status, SendErr> {
        // ...
    }
}
````

**ข้อสังเกต:** ในตัวอย่างข้างต้น บรรทัด `assert!(response.is_ok());` จะไม่ได้ถูกประมวลผลจริงในระหว่างการรันเทสต์ เพราะมันบรรจุอยู่ภายในฟังก์ชันที่ไม่มีการเรียกใช้งาน

## ข้อดี

ช่วยให้เอกสารประกอบมีความกระชับ สะอาดตา และหลีกเลี่ยงการเขียนโค้ด boilerplate ซ้ำซากจำเจในทุกๆ เมท็อด

## ข้อเสีย

เนื่องจากโค้ดตัวอย่างถูกครอบไว้ในฟังก์ชันที่ไม่มีการเรียกใช้จริง โค้ดส่วนที่เป็น assertion จึงไม่ถูกรันจริงในระหว่างทดสอบ อย่างไรก็ตาม คอมไพเลอร์จะยังคงตรวจสอบไวยากรณ์และความถูกต้องของการคอมไพล์อยู่เสมอเมื่อรันคำสั่ง `cargo test` แพตเทิร์นนี้จึงมีประโยชน์สูงสุดสำหรับกรณีที่ต้องการใช้ `no_run` โดยที่คุณไม่ต้องระบุแฟล็ก `no_run` ให้ยุ่งยาก

## เจาะลึกรายละเอียด

หากโค้ดตัวอย่างไม่จำเป็นต้องมีการรัน assertion จริงๆ แพตเทิร์นนี้ถือว่าตอบโจทย์ได้เป็นอย่างดี

แต่หากต้องการให้มีการทดสอบ assertion จริง ทางเลือกหนึ่งคือการสร้างเมท็อดแบบ public เพื่อทำหน้าที่สร้างอินสแตนซ์ทดสอบขึ้นมา แล้วกำกับด้วยแอตทริบิวต์ `#[doc(hidden)]` ไว้ (เพื่อซ่อนไม่ให้ผู้ใช้ทั่วไปมองเห็นในหน้าเอกสาร) เมื่อทำเช่นนี้ โค้ดตัวอย่างใน rustdoc ก็จะสามารถเรียกใช้เมท็อดดังกล่าวเพื่อสร้างออบเจกต์ขึ้นมาทดสอบได้อย่างสะดวก
