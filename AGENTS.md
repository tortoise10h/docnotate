## Project tech
- Ruby on Rails MVC
- FE with Hotwire ERB
- Database SQLite
- Background job with Solid queue backed by SQLite

## Code style
### Service logic
- We don't use service object in this project, instead all the logic will place in models layer
  - Even that all the logic may not be written directly to the Active Record model class but we may seperate them into a separate concern if possible, keep the Active Record model Line of code thin and just include related concerns for extend the logic of that model
  - There are some cases, the logic is too general or not actually belongs to any specific Active Record model, we may create a new PORO model class that just extend the behavior of Active Model for validation and place the logic here instead

### Modules / Concerns pattern
- Model-specific modules (tied to one Active Record model) are scoped under a pluralized namespace matching the model name and live in `app/models/<plural_model_name>/`
  - Example: For the `Document` model, model-specific modules go under the `Documents` namespace in `app/models/documents/`
  - Example file: `app/models/documents/markdown_parseable.rb` containing `module Documents; module MarkdownParseable; end; end`
  - This keeps related behavior colocated and clearly associated with its primary model
- Generic/reusable modules that can apply to any model are placed directly under `app/models/concerns/` with no parent module
  - Example file: `app/models/concerns/ast_parseable.rb` containing `module AstParseable; end; end`

### Controllers
- Controllers should be thin, not perform any complex business logic, complex business logic should be in the model layer and controller just call them

### CSS
- Use pure CSS, with BEM naming convention, 3 kinds of css file
  1. **Foundation** — base resets, typography, body/layout defaults (e.g. `foundation.css`)
  2. **Components** — reusable UI pieces like buttons, cards, empty states (e.g. `components.css`)
  3. **Pages** — styles scoped to a specific page/screen (e.g. `pages/home.css`)
- `application.css` is the manifest: it only `@import`s the other files, no direct styles

### Rails hotwire view
- Don't make 1 large ERB file which is hard to read, if there is any duplicate, re-usuable code then split it to a partial to simplify and make the view file shorter and easier to read
- If it's a separate component in the view, should also split it into partial for simplify the main view file
