# Diagram Script Examples

Reference examples for the most commonly used diagram types. Use these as starting templates and adapt to the specific use case.

## PlantUML — Sequence Diagram

```plantuml
@startuml
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName "Segoe UI"
skinparam defaultFontSize 13
skinparam ArrowColor #555555
skinparam ArrowFontSize 12
skinparam sequenceParticipantBorderColor #2C3E50
skinparam sequenceParticipantBackgroundColor #ECF0F1
skinparam sequenceLifeLineBorderColor #7F8C8D

title User Authentication Flow

actor "User" as user
participant "Web App" as app
participant "Auth Service" as auth
database "User DB" as db

autonumber

user -> app : Enter credentials
activate app

app -> auth : POST /auth/login\n{email, password}
activate auth

auth -> db : Query user by email
activate db
db --> auth : User record
deactivate db

alt Valid credentials
    auth -> auth : Generate JWT token
    auth --> app : 200 OK\n{token, refresh_token}
    app --> user : Redirect to dashboard
else Invalid credentials
    auth --> app : 401 Unauthorized\n{error: "Invalid credentials"}
    app --> user : Show error message
end

deactivate auth
deactivate app

@enduml
```

## PlantUML — Activity / Workflow Diagram

```plantuml
@startuml
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName "Segoe UI"
skinparam ActivityBorderColor #2C3E50
skinparam ActivityBackgroundColor #ECF0F1
skinparam ActivityDiamondBorderColor #E74C3C

title Order Processing Workflow

start

:Customer places order;

|#LightBlue|Payment Service|
:Validate payment details;

if (Payment valid?) then (yes)
    :Charge payment method;
    if (Payment successful?) then (yes)
        :Generate confirmation number;
    else (no)
        :Log payment failure;
        :Notify customer of failure;
        stop
    endif
else (no)
    :Return validation errors;
    stop
endif

|#LightGreen|Fulfillment Service|
:Reserve inventory;
:Create shipping label;
:Queue for dispatch;

|#LightYellow|Notification Service|
:Send confirmation email;
:Send SMS notification;

stop

@enduml
```

## PlantUML — C4 Container Diagram

```plantuml
@startuml
!include <C4/C4_Container>

title System Architecture - Container View

Person(user, "Customer", "A user of the application")

System_Boundary(system, "E-Commerce Platform") {
    Container(web, "Web Application", "React", "Serves the SPA to users")
    Container(api, "API Gateway", "Node.js / Express", "Routes and authenticates API requests")
    Container(orders, "Order Service", "Python / FastAPI", "Handles order lifecycle")
    Container(payments, "Payment Service", "Go", "Processes payments via Stripe")
    ContainerDb(db, "Primary Database", "PostgreSQL", "Stores users, products, orders")
    ContainerQueue(queue, "Message Queue", "RabbitMQ", "Async event processing")
}

System_Ext(stripe, "Stripe", "Payment processing")
System_Ext(email, "SendGrid", "Email delivery")

Rel(user, web, "Browses and purchases", "HTTPS")
Rel(web, api, "API calls", "JSON/HTTPS")
Rel(api, orders, "Routes order requests", "gRPC")
Rel(api, payments, "Routes payment requests", "gRPC")
Rel(orders, db, "Reads/writes orders", "SQL")
Rel(orders, queue, "Publishes events", "AMQP")
Rel(payments, stripe, "Processes payments", "HTTPS")
Rel(queue, email, "Triggers notifications", "HTTPS")

@enduml
```

## Mermaid — Flowchart

```mermaid
---
title: CI/CD Pipeline
---
flowchart TD
    A[Developer Push] -->|triggers| B{Branch Type?}
    B -->|feature/*| C[Run Unit Tests]
    B -->|main| D[Run Full Test Suite]
    B -->|release/*| E[Run Full Test Suite]

    C -->|pass| F[Build Docker Image]
    C -->|fail| G[Notify Developer]

    D -->|pass| H[Build & Push to Registry]
    D -->|fail| G

    E -->|pass| I[Build Release Candidate]
    E -->|fail| G

    F --> J[Deploy to Dev Environment]
    H --> K[Deploy to Staging]
    I --> L{Manual Approval?}

    L -->|approved| M[Deploy to Production]
    L -->|rejected| N[Rollback & Investigate]

    K --> O[Run Integration Tests]
    O -->|pass| P[Ready for Release]
    O -->|fail| G

    style A fill:#3498db,color:#fff
    style G fill:#e74c3c,color:#fff
    style M fill:#2ecc71,color:#fff
    style N fill:#e67e22,color:#fff
```

## Mermaid — Gantt Chart

```mermaid
---
title: Project Timeline - Q1 2026
---
gantt
    dateFormat  YYYY-MM-DD
    axisFormat  %b %d

    section Planning
    Requirements gathering     :done, req, 2026-01-06, 5d
    Architecture design        :done, arch, after req, 5d
    Technical specification    :done, spec, after arch, 3d

    section Development
    Backend API                :active, api, 2026-01-20, 15d
    Frontend UI                :active, ui, 2026-01-22, 15d
    Database schema            :done, db, 2026-01-20, 5d
    Integration                :integ, after api, 5d

    section Testing
    Unit tests                 :test1, after api, 5d
    Integration tests          :test2, after integ, 5d
    UAT                        :uat, after test2, 5d

    section Deployment
    Staging deployment         :stage, after uat, 2d
    Production release         :milestone, prod, after stage, 0d
```

## GraphViz (DOT) — Dependency Graph

```dot
digraph dependencies {
    graph [
        rankdir=LR
        fontname="Segoe UI"
        bgcolor=white
        label="Module Dependency Graph"
        labelloc=t
        fontsize=18
    ]

    node [
        shape=box
        style="rounded,filled"
        fontname="Segoe UI"
        fontsize=12
        fillcolor="#ECF0F1"
        color="#2C3E50"
    ]

    edge [
        color="#7F8C8D"
        fontname="Segoe UI"
        fontsize=10
    ]

    subgraph cluster_core {
        label="Core"
        style="dashed"
        color="#3498DB"
        config [label="config" fillcolor="#AED6F1"]
        logger [label="logger" fillcolor="#AED6F1"]
        utils [label="utils" fillcolor="#AED6F1"]
    }

    subgraph cluster_services {
        label="Services"
        style="dashed"
        color="#2ECC71"
        auth [label="auth-service" fillcolor="#ABEBC6"]
        user [label="user-service" fillcolor="#ABEBC6"]
        order [label="order-service" fillcolor="#ABEBC6"]
    }

    subgraph cluster_api {
        label="API Layer"
        style="dashed"
        color="#E74C3C"
        gateway [label="api-gateway" fillcolor="#F5B7B1"]
        middleware [label="middleware" fillcolor="#F5B7B1"]
    }

    gateway -> middleware [label="uses"]
    gateway -> auth [label="authenticates"]
    middleware -> logger [label="logs to"]
    auth -> user [label="validates"]
    auth -> config [label="reads"]
    user -> utils [label="uses"]
    order -> user [label="lookups"]
    order -> logger [label="logs to"]
}
```

## D2 — Architecture Diagram

```d2
title: |md
  # Microservices Architecture
| {near: top-center}

direction: right

clients: {
  label: "Client Layer"
  style.fill: "#E8F4FD"

  web: Web Browser {shape: rectangle}
  mobile: Mobile App {shape: rectangle}
}

gateway: API Gateway {
  shape: hexagon
  style.fill: "#FFF3CD"
}

services: {
  label: "Service Layer"
  style.fill: "#D4EDDA"

  auth: Auth Service {shape: rectangle}
  users: User Service {shape: rectangle}
  orders: Order Service {shape: rectangle}
  notifications: Notification Service {shape: rectangle}
}

data: {
  label: "Data Layer"
  style.fill: "#F8D7DA"

  postgres: PostgreSQL {shape: cylinder}
  redis: Redis Cache {shape: cylinder}
  queue: Message Queue {shape: queue}
}

external: {
  label: "External"
  style.fill: "#E2E3E5"

  stripe: Stripe {shape: cloud}
  sendgrid: SendGrid {shape: cloud}
}

clients.web -> gateway: HTTPS
clients.mobile -> gateway: HTTPS

gateway -> services.auth: Authenticate
gateway -> services.users: User CRUD
gateway -> services.orders: Order CRUD

services.auth -> data.redis: Session cache
services.users -> data.postgres: Read/Write
services.orders -> data.postgres: Read/Write
services.orders -> data.queue: Publish events
data.queue -> services.notifications: Consume events

services.orders -> external.stripe: Process payment
services.notifications -> external.sendgrid: Send email
```

## ERD — Entity Relationship Diagram

```erd
title {label: "E-Commerce Database Schema"}

[Customer] {bgcolor: "#ECF0F1"}
  *id {label: "int, PK"}
  email {label: "varchar(255), unique"}
  name {label: "varchar(100)"}
  created_at {label: "timestamp"}

[Product] {bgcolor: "#ECF0F1"}
  *id {label: "int, PK"}
  name {label: "varchar(200)"}
  price {label: "decimal(10,2)"}
  category_id {label: "int, FK"}

[Order] {bgcolor: "#D5F5E3"}
  *id {label: "int, PK"}
  customer_id {label: "int, FK"}
  status {label: "enum"}
  total {label: "decimal(10,2)"}
  created_at {label: "timestamp"}

[OrderItem] {bgcolor: "#D5F5E3"}
  *id {label: "int, PK"}
  order_id {label: "int, FK"}
  product_id {label: "int, FK"}
  quantity {label: "int"}
  unit_price {label: "decimal(10,2)"}

[Category] {bgcolor: "#FADBD8"}
  *id {label: "int, PK"}
  name {label: "varchar(100)"}

Customer 1--* Order {label: "places"}
Order 1--* OrderItem {label: "contains"}
Product 1--* OrderItem {label: "included in"}
Category 1--* Product {label: "categorizes"}
```

## NwDiag — Network Diagram

```nwdiag
nwdiag {
    internet [shape = cloud];
    internet -- router;

    network dmz {
        address = "210.x.x.x/24"
        color = "#FADBD8"

        router [address = "210.x.x.1"];
        firewall [address = "210.x.x.2"];
        web01 [address = "210.x.x.10", description = "NGINX\nLoad Balancer"];
    }

    network internal {
        address = "172.x.x.x/24"
        color = "#D5F5E3"

        firewall [address = "172.x.x.1"];
        app01 [address = "172.x.x.10", description = "App Server 1\nNode.js"];
        app02 [address = "172.x.x.11", description = "App Server 2\nNode.js"];
    }

    network data {
        address = "192.168.x.x/24"
        color = "#AED6F1"

        app01 [address = "192.168.x.10"];
        app02 [address = "192.168.x.11"];
        db01 [address = "192.168.x.20", description = "Primary DB\nPostgreSQL"];
        db02 [address = "192.168.x.21", description = "Replica DB\nPostgreSQL"];
        cache [address = "192.168.x.30", description = "Redis\nCache"];
    }
}
```
