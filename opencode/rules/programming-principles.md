# Core Programming Principles

Universal principles applied across all languages. Language-specific rules extend these.

## SOLID Principles

| Principle | Meaning | Application |
|-----------|---------|-------------|
| **SRP** (Single Responsibility) | One reason to change | Each module/type/function does one thing |
| **OCP** (Open/Closed) | Open for extension, closed for modification | Use composition, interfaces, polymorphism |
| **LSP** (Liskov Substitution) | Subtypes must be substitutable | Honor contracts, no surprising behavior |
| **ISP** (Interface Segregation) | No forced dependencies on unused methods | Small, focused interfaces |
| **DIP** (Dependency Inversion) | Depend on abstractions | Accept interfaces, inject dependencies |

## Design Heuristics

| Principle | Meaning | When to Apply |
|-----------|---------|---------------|
| **KISS** | Keep It Simple | Prefer clarity over cleverness |
| **YAGNI** | You Aren't Gonna Need It | Add abstractions only when needed |
| **DRY** | Don't Repeat Yourself | Extract when pattern repeats 3+ times |

### DRY Nuance

DRY is about **knowledge**, not code characters. Acceptable duplication:
- Two similar code blocks with different reasons to change
- Coupling cost exceeds duplication cost
- "A little copying is better than a little dependency"

## Composition Over Inheritance

- Prefer composition for flexibility
- Use interfaces/traits for polymorphism
- Embed/delegate rather than inherit

## Fail Fast

- Validate inputs early
- Return errors immediately
- Don't hide failures

## Law of Demeter

- Talk to immediate collaborators only
- Avoid: `a.getB().getC().doThing()`
- Prefer: `a.doThing()` (a delegates internally)

## Naming

- Names reveal intent
- Functions: verb or verb-phrase (`createUser`, `validateInput`)
- Types: noun or noun-phrase (`UserRepository`, `OrderService`)
- Booleans: question form (`isValid`, `hasPermission`, `canExecute`)
- Avoid abbreviations except well-known ones (`ctx`, `err`, `req`)

## Functions

- Do one thing
- Few parameters (ideally ≤3)
- No side effects beyond stated purpose
- Return early for guard clauses

## Comments

- Explain **why**, not what
- Code should be self-documenting
- Comments for: intent, warnings, TODOs, public APIs

## Anti-Patterns (Universal)

| Pattern | Problem | Fix |
|---------|---------|-----|
| God object | Too many responsibilities | Split by domain |
| Deep nesting | Hard to follow (>3-4 levels) | Extract, return early |
| Magic numbers | Unclear meaning | Named constants |
| Premature abstraction | Complexity without need | Wait for 2+ use cases |
| Shotgun surgery | One change touches many files | Better cohesion |
