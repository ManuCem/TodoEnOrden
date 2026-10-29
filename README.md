# TodoenOrden

A small mobile-first web app for people who share a flat. It keeps the everyday logistics of a shared home in one place: who lives there, what needs buying, who cleans what this week, and which bills are coming up.

The interface is in Spanish. The whole app is a single file, [`todoenorden_v2.html`](todoenorden_v2.html), with no build step.

## Features

The app has four sections, reachable from the bottom navigation bar.

| Section | What it does |
| --- | --- |
| **Piso** (Flat) | Shows the flat's 6-letter invite code (displayed as fridge-magnet letters) with a copy button, lists the flatmates, lets you change your name, and lets you leave the flat. |
| **Compra** (Shopping) | A shared shopping list. Add products, tick them off as bought, or remove them. Duplicate names are rejected. |
| **Limpieza** (Cleaning) | Define cleaning zones (bathroom, kitchen, living room...). Each week the zones rotate to the next flatmate. You can only tick off your own tasks, and a progress bar shows how many are done, coloured by who cleaned them. |
| **Facturas** (Bills) | Register recurring bills (name, amount, frequency, next due date, who advances the money). Bills are sorted by due date and flagged as due soon, due today, or overdue. Frequencies: weekly, monthly, bimonthly, quarterly, yearly. |

### Onboarding

On first use you enter your name and then either:

- **create a flat**, which gives you a 6-character invite code to share, or
- **join a flat** by typing the code a flatmate gave you.

Each flatmate gets their own "magnet" colour (six colours, assigned by the order they joined the flat). The app supports light and dark mode automatically.

## How it works

- **Frontend:** plain HTML, CSS and vanilla JavaScript in one file. The Archivo font is loaded from Google Fonts.
- **Backend:** [Supabase](https://supabase.com) (Postgres + Auth), loaded from a CDN through `@supabase/supabase-js`.
- **Authentication:** anonymous sign-in. There is no email or password; each browser gets its own anonymous user. Because of this, clearing your browser data means losing access to your user, and you would need to rejoin the flat with the invite code.
- **Data used:** the tables `profiles`, `apartments`, `apartment_members`, `shopping_items`, `cleaning_zones`, `cleaning_assignments` and `recurring_bills`, plus the database functions `create_apartment`, `join_apartment` and `ensure_week_assignments`. Access is protected with Postgres row-level security.

## Running it

1. Clone the repository and open `todoenorden_v2.html` in a browser (double-click it, or serve the folder with any static server).
2. The app connects to the Supabase project configured at the top of the script (`SUPABASE_URL` and `SUPABASE_KEY`). That key is a publishable (public) key, which is meant to be used in the browser; the data is protected by row-level security.
3. In the Supabase dashboard, **Allow anonymous sign-ins** must be enabled under **Authentication → Sign In / Providers**. If it is not, the app shows a connection error with these exact steps.

### Demo mode

To try the app without a database, add `?demo` to the URL, for example `todoenorden_v2.html?demo`. It loads in-memory example data (a flat with three flatmates, a shopping list, cleaning zones and three bills). Nothing is saved, and the header shows "Datos de ejemplo". You can also reach demo mode from the connection error screen.

## Using your own Supabase project

To run your own copy instead of the existing backend:

1. Create a Supabase project and enable anonymous sign-ins.
2. Create the tables and functions listed above, with row-level security policies that limit each table to the members of the same flat.
3. Replace `SUPABASE_URL` and `SUPABASE_KEY` at the top of the script with your project's URL and publishable key.

## Contributing

Anyone who needs to edit the project must be added as a collaborator under **Settings → Collaborators** on GitHub. Changes are best proposed on a branch through a pull request.
