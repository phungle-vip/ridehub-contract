# RideHub Contract

Repository quản lý hợp đồng giao tiếp (contracts, API schemas, Avro events) chuẩn cho hệ sinh thái microservices RideHub.

## Trách nhiệm (Ownership)
- Là **Source of Truth** duy nhất cho các đặc tả giao tiếp giữa các microservices.
- Sở hữu OpenAPI, AsyncAPI, Avro schemas, JSON schemas.
- Có versioning và backward compatibility policy rõ ràng.
- **Không** chứa runtime business logic, database queries, Kafka connections, hay thông tin bí mật/secret môi trường.

## Cấu trúc thư mục

```
ridehub-contract/
├── src/main/
│   ├── openapi/        # Định nghĩa REST API specs (OpenAPI 3.0 / Swagger)
│   ├── asyncapi/       # Định nghĩa Event-driven specs (AsyncAPI)
│   ├── avro/           # Avro schemas (.avsc) cho Kafka messages
│   └── json-schema/    # JSON schemas dùng chung
├── examples/           # Các mẫu payload request/response/event JSON
└── contract-tests/     # Script kiểm tra cú pháp và validate contract
```

## Luồng hoạt động (Workflow)
1. Cập nhật schema/API/event contract trong `ridehub-contract`.
2. Kiểm tra tính tương thích (backward compatibility) và linting schema.
3. `ridehub-shared` consume contract/schema từ repository này để generate DTO, model và Feign clients.
4. Các microservice trong `backend/` sử dụng shared library từ `ridehub-shared` hoặc schema models để giao tiếp.
