# ⚠️ WARNING: VIBE CODED SLOP

Simple WoW addon for tracking NPC kills and item drop sources.

## ✨ Features

- **🎯 Kill Tracking**: Automatically records kills of unique NPCs.
- **🧬 Species Tracking**: Logs kills by NPC species.
- **💰 Mob value tracking**: Logs kills, displaying average vendor and auction values of that NPC.
- **💰 Drop Source Discovery**: Records items dropped by NPCs to help you find where to farm them later.

## ⌨️ Slash Commands

- `/kwakills` — Displays your total kills and the top 5 most killed NPCs.
- `/kwaracekills` — Displays your kill counts categorized by NPC race / species.
- `/kwafind [Item Link/Name]` — Searches for NPCs that have dropped a specific item and shows their calculated drop rates.
- `/kwatopvendor` — Displays the top 10 most profitable NPCs based on vendor value.
- `/kwatopauction` — Displays the top 10 most profitable NPCs based on auction value (requires Auctionator).
- `/kwapurge` — Clears all loot and value data to remove outliers (kill counts are preserved).
- `/kwahelp` — Displays a list of all available slash commands.

## 🖱️ Tooltips

- **Shift + Hover** 🖱️: Hold the `Shift` key while hovering over an item in your inventory or a merchant window to see the top 3 NPC sources and their calculated drop rates based on your recorded data.

# ⚠️ REQUIRES THIS WEAKAURA TO DISPLAY INFO ON TARGETS
If you wish to hide some of the displayed information, comment out the relevant lines in the display tab of the weakaura text component (the bools at the top).

```
!WA:2!nEv3UTXXvyPsKMMnTf2QjoP2Pnd2K4s2irljBP2QcLgsksjgtlQsUsYbog0d3DwUt9YD2mZSYIUOOfcff5AFBVtx3Rya61f(UE3aH(eOhbJ(a0ZSd)ZsKrLqA)BoZ589DoFZSND(dwq0ET8RUs(1xO7cEl49nF4zTXUp1JZIlXcz8VitMm7Lz58RDEBg3JWloyW4RvmK(8NJ5EihglusJpvYCpIWfuw0pyX)7z4ezaJxpwc3lSAGdJdWzABCsWl6WzjXvDzrVFM)()UpoYfSDpgns2Uu5DDk34uJHnPpN8g8JR77liYD(8UVL)FzU5(E9ndAW38ZpFMbwx2Rdj(6n)6emNGQKegIomGkjNYjDaq40lM0inUCSBkQwVHqI5sR2(0iQiWQiCsADIKt70biYnVnFWL)Tt9iTt891UGVt5A7vz)AfLA)Ht44vpretcdR6jSoxK0MCejs2eSMEC)wLk00PvtNcnCkMaoVDCiUhHpYS94eWSgn3RCTAnsFs7Di4qzqJiCxIW6fjrdGGvdHloKK5LgQAYiVfV3WuZr)51)xZn38Vahr7I1SBD17u5LeSG0uYjrDKbVP6wfJyrKZ8amRTOLMbCbbQcEIt0MQ5NAPIDX0OkQfHjOwsLxDh1YW539IpXM6D(9Fg((0WWsmaNe(RO6Jr4WdmYGVTVphObaaSeN5vMQCf9J0bQDZsnkxE3(0iFg3GzRvtOE93ENT6vjG9LDYU2leKq)uDH6TpfsAnsRKcRbkGQra3ZCQMauJoRyid7vPTesvrYB0OBcOmTkc1h3BO(CRgUHyHqFvrbOS0x0gMSpTJ1cU38BweehYqAeP4UqEQH7q9FM4p1Jk0LohYXYwg42kULK2L0YRhuQOUTKbCIiGf617u3eHK1vB7XVPTFsuQAlBole8BPLqp6rOs13Ts1T3VrbNQ13f94hpCOMejsgqeeKKHK8ecIXr(4qZda3)S7eq9iinHO(uxKgTcenspl0He8tlaf3uVfYa9cQ5o1pS19RwRwt0MPo8IJv4GTBDq5D3QEJVddkSZmgm1ZTCQ3Qw5dkxBsJspq9hHjr(QIbBgupMazdnIJmMP)XjYeEeYwlNeBGwF91)QOch1bDajYJX3aTIaT6YUMNvyNnqRkqRPV3HHQblCc3aDVvTnUdMXyiyaBhqxbOBFyj427xDRS2W6(oePDUHWmIjngLIQHGXEA(sVowRFxe1AI)IIDRUfecHKdkfQmR9s2lM6YxlgzhoB0MBISlXjyiseBDz(1g5asa1nKyNtpIEIg)F1OZdwQbW4b9gTU0b3oKGWrEx6Hpk1PpEs8Lo9Rokgz3MO)4FA8iG8DL8O06hkngd97eAqTNhvYnUYvBk4kDKZBUbO8YJSsQrAEkSsNlZMg3f1jzAuN8MfIzhQz(epiJN6HC5USqaG3Q5rfG3qH7qgiRqhGdhOxhIZjwpOtzPOcFuNAmMm14z80pdT8RtUPbB7jf02O85rBtKLGD30BvaYGMP0klWPG8(Hmgp7LcuUzqT7oMAfss3VzgCdwkRzae4TmBCnWCdnMs95i4)nNH9ztfq5gndiqAZ1bqF(sjLVZeJEv9)xjfW1dtdtMkUyk5EdfJYbBrCz944DUgvvpo(1U(suyGOnHdVuv(W9gSPYd3lRT5v725UGPDXhpHzpaF8mT844DjepIEJkZKwACCMmfpYUPMFn(6PAM7Ws5DQ)GSNlHgMD0KVZqoM7QlpJ3KnTanPZVI6WGDrmEfEvRlESx)QiifawFMia7XE2xAAL5dMtzPE7y0SFJR5U5JV243ZUFmqgI6Jph66KP7LW9qQNmOyb4w1pbAfYs9UwQByPEVF8TvV))eAJbDwIG0kGjKuy36EbQFU6dvFC87OltOsbyDpIeofg2vOSvFK6NzPqTnV24e9u1Bx)e1TToxFdwkH(I1K8jQFQ6MQFHv811nzEeXX0(2dyEK)XCX3AQSYCrdn58IV9SjEiPd2TxR0vbbQpv3H3f7sBLRUVT4pykrWD1bxbT)5ZIKXxRcN(C0Vpb7PBEd54O(T38gQBDg0eM(7d09rh5P(SkQFNUlkvH0JftpwsF8eTx0TV)EdkVp0uEZOwtTU66fLqWNoswzesu)Y5vBA1FcJS)ex1gTlw3XP(dI)OzNPI5q)r6wqZO(rZR2Yk2E222L51c4i5j8)aONO(9kwRCfh1BaFed0IlFlZep5zqhNhYXXNC4Glu3lZ0jWDhrGPwVDhZVFD)Lp8(F9H9c)nFH)wQVVvFtQAIpSb(6aIxQw(V(dv)kl1D)2fo6)8W)h
```

