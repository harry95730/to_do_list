Orchestrate | Task Management System
A visually polished, functionally robust Task Management application built with Flutter. This project follows Clean Architecture principles and uses the BLoC pattern for state management, ensuring a highly maintainable and testable codebase.

Architectural Overview
The app is structured into three distinct layers to ensure a strict separation of concerns:

Domain Layer: Contains the TaskEntity and abstract ToDoRepository. This is the core business logic, independent of any external libraries.

Data Layer: Implements the repository using SharedPreferences for persistence. It handles data mapping between TaskModel (JSON) and TaskEntity. [In future we can add the backend logic here, as a part of task I choose with local data persistance.]

Presentation Layer: Uses the BLoC/MVVM pattern. UI components are "dumb" and only react to states emitted by the TaskListBloc.

Features Implemented
Core Requirements

Full CRUD: Create, Read, Update, and Delete tasks seamlessly.

Status Management: Tasks move through "To-Do", "In-Progress", and "Completed" states.

Dependency Logic: Implementation of "Blocked By" logic. If Task B is blocked by Task A, Task B appears greyed out and is non-interactive until Task A is marked as "Done".

Persistence: All data is persisted locally using the shared_preferences package.

Draft System: Automatic local caching of task input. If the user exits the creation screen prematurely, their progress is restored upon return.


Stretch Goals & UX Polishing

Debounced Search: Real-time filtering to optimize performance.

Text Highlighting: Matching search queries are highlighted within the Task Title and Description.

Swipe-to-Delete: Intuitive gestures with a "Yes/No" confirmation dialog to prevent accidental data loss.

Tab-Based Navigation: Categorized views for All, To-Do, In-Progress, and Completed tasks.

Collapsible Sections: "Active Sequence" and "Dependencies" sections use an accordion-style UI to reduce cognitive load.