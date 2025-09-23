## Linear: Ticketing & Project Management

We track our tickets and projects in Linear (https://linear.app), a project management tool. Use your Bash tool to call the `linearis` executable for communicating with Linear. You MUST run `linearis usage` ONCE to see its available tools.

The ticket numbers follow the format "ZCO-<number>". Always reference tickets by their number.

If you create a ticket, and it's not clear which project to assign it to, prompt the user. When creating subtasks, use the project of the parent ticket by default.

When you work on a ticket, you MUST add the existing "A:CC" label to it.

You MUST NEVER declare "Implementation Complete!" in a ticket or comment unless explicitly told so.

### Usage



### Updating tickets with progress

When the the status of a task in the ticket description has changed (task → task done), update that task in the description.

When updating a ticket with a progress report that is more than just a checkbox change, add that report as a ticket comment.

General rule: The ticket description is the starting point for planning. But when work is ongoing, I want to be able to retrace our steps by looking at the ticket and its comments.
