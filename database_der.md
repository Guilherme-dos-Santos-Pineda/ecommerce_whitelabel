# Diagrama Entidade-Relacionamento (DER)

## Entidades

### clients
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | INTEGER (PK) | ID único |
| name | VARCHAR | Nome do cliente |
| domain | VARCHAR (UNIQUE) | Domínio único |
| primary_color | VARCHAR | Cor do tema |
| provider_type | VARCHAR | 'brazilian', 'european', 'both' |
| created_at | DATETIME | Data de criação |

### users
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | INTEGER (PK) | ID único |
| name | VARCHAR | Nome do usuário |
| email | VARCHAR (UNIQUE) | Email único |
| password_hash | VARCHAR | Hash da senha (bcrypt) |
| client_id | INTEGER (FK) | Referência ao cliente |
| created_at | DATETIME | Data de criação |

## Relacionamentos
