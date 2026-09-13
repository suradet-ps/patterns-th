# การเริ่มต้นเอกสารประกอบอย่างง่าย

## คำอธิบาย

หาก struct ต้องใช้ความพยายามอย่างมากในการเริ่มต้นเมื่อเขียนเอกสารประกอบ การห่อตัวอย่างของคุณด้วยฟังก์ชันตัวช่วยที่รับ struct เป็นอาร์กิวเมนต์จะรวดเร็วกว่า

## แรงจูงใจ

บางครั้ง struct หนึ่งมีพารามิเตอร์หลายตัวหรือซับซ้อน และมีเมท็อดหลายตัว แต่ละเมท็อดเหล่านี้ควรมีตัวอย่างประกอบ

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

แทนที่จะพิมพ์โค้ด boilerplate ทั้งหมดนี้เพื่อสร้าง `Connection` และ `Request` การสร้างฟังก์ชันตัวช่วยห่อที่รับค่าเหล่านั้นเป็นอาร์กิวเมนต์จะง่ายกว่า:

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

**หมายเหตุ** ในตัวอย่างข้างต้น บรรทัด `assert!(response.is_ok());` จะไม่ถูกเรียกใช้จริงตอนทดสอบ เพราะมันอยู่ภายในฟังก์ชันที่ไม่เคยถูกเรียก

## ข้อดี

วิธีนี้กระชับกว่ามากและหลีกเลี่ยงโค้ดซ้ำซากในตัวอย่าง

## ข้อเสีย

เนื่องจากตัวอย่างอยู่ในฟังก์ชัน โค้ดจึงไม่ถูกทดสอบ ถึงกระนั้นมันจะยังถูกตรวจสอบว่าคอมไพล์ผ่านเมื่อรัน `cargo test` ดังนั้นแพตเทิร์นนี้มีประโยชน์ที่สุดเมื่อคุณต้องการ `no_run` ซึ่งเมื่อใช้วิธีนี้แล้วคุณไม่จำเป็นต้องใส่ `no_run` อีก

## การอภิปราย

หากไม่จำเป็นต้องมี assertion แพตเทิร์นนี้ก็ทำงานได้ดี

หากจำเป็น ทางเลือกหนึ่งคือสร้างเมท็อดสาธารณะสำหรับสร้างอินสแตนซ์ตัวช่วย ซึ่งติดแอตทริบิวต์ `#[doc(hidden)]` ไว้ (เพื่อไม่ให้ผู้ใช้เห็น) จากนั้นเมท็อดนี้สามารถถูกเรียกภายใน rustdoc ได้ เพราะมันเป็นส่วนหนึ่งของ API สาธารณะของครีต
