# teaBASE

A macOS preference pane that levels up the security and power of your
development environment.

[Download](../../releases/latest)

> [!WARNING]
> teaBASE is in *beta*, almost certainly there are edge cases we are not yet
> catering to. Please report any issues you encounter.


## Secure Development

Get your SSH as secure as possible and set up secure GPG signing for your
commits.

Our `gpg` signing is best in class secure with way less bloat, hassle and
overhead than GNU’s GPG suite.

> [!TIP]
> We store your GPG private key in the macOS keychain, signed such that it is
> is impossible for any other app to get it. We never expose it, it is fetched
> for as small a time as possible into memory, used to sign your commits and
> then discarded.

> [!NOTE]
> We use a custom fork of [withoutboats]’s [bpb].


## Dotfile Sync

> [!NOTE]
> Dotfiles are `.` prefixed files in your home directory and are how open
> source stores configuration.

teaBASE’s dotfile sync keeps your dotfiles versioned, backed up to a private
GitHub repo and synchronized to any number of computers automatically.
You can easily override, restore or otherwise fiddle with how it works because
it’s all just `git` under the hood.


## Contributing

> [!NOTE]
> teaBASE requires Xcode >=16, which requires macOS >=14.5.
> You can check device compatibility [here].

Prefpanes are fiddly.

1. Build the prefpane with Xcode.
2. Select to show the build folder from the *Product* menu
3. Quit “System Settings.app” (if open) †
4. Open the `.prefPane` product from inside the `Debug` subfolder

> † System Settings.app doesn’t seem to otherwise reload the `.prefPane`
> bundle.

Debugging is hard. In theory you can connect the debugger. In practice logging
with a `teaBASE:` prefix and filtering in “Console.app” or showing
`NSAlert`s is the path of least resistance.

[here]: https://support.apple.com/en-us/105113


## FAQ

### Why is this a Preference Pane Rather than a `.app`?

More tools like this *should* be Preference Panes in our opinion. You don’t need Menu Bar apps or clutter in your `/Applications` for rarely used configuration tools. If you disagree we’d like to hear your take though.


### Why is this Written in Objective-C rather than Swift?

Preference Panes are old school and the continued integration of them into macOS is not well documented nor well supported. We didn’t want to risk potential deployment hassles by choosing
Swift here even though we would prefer Swift.


[bpb]: https://github.com/pkgxdev/bpb
[withoutboats]: https://github.com/withoutboats
