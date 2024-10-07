# teaBASE

A macOS preference pane that enables secure and powerful development.

> [!NOTE]
> teaBASE is prerelease. Come back soon!

> [!WARNING]
> teaBASE is in *beta*, almost certainly there are edge cases we are not yet
> catering to. Please report any issues you encounter.


## Goals

We aim to make setting up secure development as simple or zero configuration
as possible. We’re not quite there, but it’s pretty good.


## Mechanisms

* SSH configuration is standard. macOS makes it trivial to use iCloud keychain for passphrases.
* For gpg signing we use [bpb] which is a bare bones gpg signer designed for git commits.


## TODO

* Use Touch ID for authenticated steps
  * There doesn’t seem to be a clear, endorsed way to do this without using AppleScript
* Configurability 💪
  * We’re developers, let’s make this thing configurable *AF*.
  * mxcl will insist on good UX though…
* Option to store `bpb` private keys in the keychain
  * The default stores the private key as plain text in `~/.bpb_config.toml` and thus is not suffiiently secure
  * `bpb` can accept the key via stdin
  * macOS provides the `security` tool which can output keychain values
  * Ideally we can configure it so it can prompt for Touch ID every time
    * Not everyone will like this, but some of us are cool with it
* Prefill GPG sign dialog
  * Username from the system
  * Email from `git config` or iCloud account
* Error handling needs improvement
* Contingency handling needs improvement
* Tool execution is all synchronous
* Aesthetics
  * The preference pane is loaded with a wider width that standard System Settings.
    Presumably because the legacy System Preferences app was this width.
    We don’t want this.

## Contributing

Prefpanes are fiddly.

1. Build the prefpane with Xcode.
2. Select to show the build folder from the *Product* menu
3. Open the `.prefPane` product from inside the `Debug` subfolder

Do this every time you need to test changes. Note that you should *Quit* “System Settings.app” every time you need to replace teaBASE since it does not reload the bundle otherwise.

Debugging is hard. In theory you can connect the debugger. In practice logging distinctive prefixed strings and filtering in “Console.app” or showing NSAlerts is the path of least resistance.


## FAQ

### Why is this a Preference Pane Rather than a `.app`?

More tools like this *should* be Preference Panes in our opinion. You don’t need Menu Bar apps or clutter in your `/Applications` for rarely used configuration tools. If you disagree we’d like to hear your take though.


### Why is this Written in Objective-C rather than Swift?

Preference Panes are old school and the continued integration of them into macOS is not well documented nor well supported. We didn’t want to risk potential deployment hassles by choosing
Swift here even though we would prefer Swift.



[bpb]: https://github.com/withoutboats/bpb
