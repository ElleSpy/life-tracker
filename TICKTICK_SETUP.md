# Connecting TickTick

TickTick sync is fully built in the app — it just needs **your** API credentials,
because TickTick (like every cloud service) requires each app to register with
them. This is a one-time, ~5-minute setup. No coding required.

## Step 1 — Register a TickTick developer app

1. Go to the TickTick Developer Center: **https://developer.ticktick.com/manage**
   (sign in with your normal TickTick account).
2. Click **New App** (or "Create App"). Give it a name like "LifeTracker".
3. After creating it, you'll see a **Client ID** and **Client Secret** — keep
   this page open, you'll copy them in Step 3.
4. Set the **OAuth redirect URL** to exactly:

   ```
   lifetracker://ticktick-auth
   ```

   Save.

## Step 2 — Create your Secrets file

In the project folder, copy the template to a real secrets file:

- Duplicate **`Secrets.example.plist`** (in the project root)
- Move the copy to **`LifeTracker/Secrets.plist`** (this exact path)

`Secrets.plist` is git-ignored, so your keys never get committed or shared.

> In Xcode you can also drag `Secrets.plist` into the **LifeTracker** group in
> the left sidebar if it doesn't appear automatically — make sure "LifeTracker"
> is ticked under *Target Membership* on the right.

## Step 3 — Paste in your keys

Open `LifeTracker/Secrets.plist` and replace the placeholders with the values
from Step 1:

| Key | Value |
| --- | --- |
| `TickTickClientID` | your Client ID |
| `TickTickClientSecret` | your Client Secret |
| `TickTickRedirectURI` | leave as `lifetracker://ticktick-auth` |

## Step 4 — Use it

1. Build and run the app.
2. **Profile → Connections → Connect a to-do app → TickTick.**
3. A TickTick login sheet appears; authorise LifeTracker.
4. Go to the **Plan** tab and tap **Sync** (top-left) to pull your tasks in.

## Notes & limitations

- Your token is stored in the device **Keychain**, not in the code or iCloud.
- This is a first pass: it **imports** open tasks from your TickTick projects
  into Plan. It doesn't yet push changes back to TickTick or delete completed
  tasks there — say the word and I'll extend it.
- If TickTick rejects the custom `lifetracker://` redirect URL, tell me and I'll
  switch the flow to a different redirect style.
- Inbox-only tasks may not appear depending on TickTick's API; tasks inside
  projects/lists will.
