
### **3. Documentação da Arquitetura**


```markdown
# Arquitetura do Sistema

## Visão Geral
Sistema de e-commerce whitelabel com frontend em Flutter e backend em NestJS.

## Stack Tecnológica

### Frontend
- **Flutter** - Framework UI multiplataforma
- **http** - Cliente HTTP para APIs
- **shared_preferences** - Persistência local

### Backend
- **NestJS** - Framework Node.js com TypeScript
- **TypeORM** - ORM para banco de dados
- **SQLite** - Banco de dados (desenvolvimento)
- **JWT** - Autenticação stateless
- **bcrypt** - Hash de senhas

## Arquitetura Whitelabel

### Domínios e Temas
- `devnology.com` → Tema verde + produtos brasileiros
- `in8.com` → Tema roxo + produtos europeus

### Fluxo de Autenticação
1. Usuário faz login → API valida credenciais
2. Gera JWT token com informações do cliente
3. Token é usado em requisições subsequentes
4. Produtos são filtrados pelo provider_type do cliente

### Agregação de Produtos
- API consome dois fornecedores externos
- Produtos são normalizados em formato unificado
- Filtragem baseada no provider_type do cliente

## Decisões de Arquitetura

### Por que Flutter?
- Desenvolvimento multiplataforma (web, mobile)
- Hot reload para desenvolvimento ágil
- Performance nativa

### Por que NestJS?
- Arquitetura modular e escalável
- TypeScript para type safety
- Ecossistema robusto

### Por que SQLite?
- Simplicidade para desenvolvimento
- Zero configuração

- Fácil deploy
