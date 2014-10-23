sandlot
=======

A sandbox viewer for iOS Simulators

Note: As it currently stands, running an application renames the directory that the application and its sandbox are in. These changes are noted in the backboard property list inside a simulator's directory, but take a few seconds to propagate. Thus, when re-running an application, the sandbox is invalid for a moment.

Additionally, there is no filesystem watcher on the sandbox itself right now. (Until I, or someone else, consolidates the file system watchers to handle changes to the backboard and individual sandboxes.) For now, you can reload a sandbox you believe changed by clicking on the application again.
