# Maintainer documentation

Various details of note to maintainers.

## Change policy

**Push**

- Small-to-medium patches within the scope of your maintainership
- Small patches outside the scope of your maintainership
- Patches of any size from third party contributors following code review
- Large patches of your own following code review

## Caution!

- API changes (breaking changes automatically make the patch "large")
- Sufficient/up-to-date documentation

## Recommended mail configuration

[aerc] is the recommended mail client for Hare maintainers. It has features to
ease the patch workflow and to help other maintainers keep up with your work,
and a suitable configuration makes for a comfy environment to do your code
reviews in.

[aerc]: https://aerc-mail.org/

Specific recommendations follow:

**~/.config/aerc/aerc.conf**

```
[ui]
# Enables the styleset provided in the next code block
styleset-name=hare
```

**~/.config/aerc/stylesets/hare**

Adjust to taste.

```
# Highlights emails which modify the sourcehut patch status
msglist*.X-Sourcehut-Patchset-Update,APPLIED.fg = blue
msglist*.X-Sourcehut-Patchset-Update,APPLIED.selected.reverse = true
msglist*.X-Sourcehut-Patchset-Update,NEEDS_REVISION.fg = yellow
msglist*.X-Sourcehut-Patchset-Update,REJECTED.fg = red
```

**~/.config/aerc/binds.conf**

Recommended additional keybindings:

```
[messages]
# Reply with standard "Thanks!" message, auto-setting patch status on sourcehut
rt = :unflag<Enter>:reply -a -Tthanks<Enter>
# Same but quotes the email so you can add comments
Rt = :unflag<Enter>:reply -qa -Tquoted_thanks<Enter>

# Applies the selected patch
ga = :flag<Enter>:pipe -mb git am -3<Enter>

[view]
# Ditto
ga = :flag<Enter>:pipe -mb git am -3<Enter>

[compose::review]
# Extra key bindings when reviewing a reply to manually set sourcehut patch
# status headers
V = :header -f X-Sourcehut-Patchset-Update NEEDS_REVISION<Enter>
A = :header -f X-Sourcehut-Patchset-Update APPLIED<Enter>
R = :header -f X-Sourcehut-Patchset-Update REJECTED<Enter>
```

**~/.config/aerc/templates/thanks**

Mail template for thanking contributors for their patch (bound to "rt"
keybinding). Includes details about your last git push and sets the appropriate
patch headers.

```
X-Sourcehut-Patchset-Update: APPLIED

Thanks!

{{exec "branch=$(git rev-parse --abbrev-ref HEAD); printf 'to %s\n  %s..%s  %s -> %s\n' $(git remote get-url --push origin) $(git reflog -2 origin/$branch --pretty=format:%h | tail -n1) $(git reflog -1 origin/$branch --pretty=format:%h) $branch $branch" ""}}
```

**~/.config/aerc/templates/quoted_thanks**

Ditto but quotes the original email for comment:

```
X-Sourcehut-Patchset-Update: APPLIED

Thanks!

{{exec "branch=$(git rev-parse --abbrev-ref HEAD); printf 'to %s\n  %s..%s  %s -> %s\n' $(git remote get-url --push origin) $(git reflog -2 origin/$branch --pretty=format:%h | tail -n1) $(git reflog -1 origin/$branch --pretty=format:%h) $branch $branch" ""}}

On {{dateFormat (.OriginalDate | toLocal) "Mon Jan 2, 2006 at 3:04 PM MST"}}, {{(index .OriginalFrom 0).Name}} wrote:
{{wrapText .OriginalText 72 | quote}}
```
