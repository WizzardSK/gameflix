# Chybajuce MAME systemy v Gameflixe

Porovnanie platforms.csv s MAME software listami (hash subormi).
Generovane: 2026-03-01

---

## Nove konzoly a handheld systemy

| System | Software list | MAME driver | Titulov | Poznamka |
|--------|--------------|-------------|---------|----------|
| Apple Pippin | `pippin` | `pippin -cdrm` | 89 | Apple herny system (1996) |
| RCA Studio II | `studio2` | `studio2 -cart` | 40 | Retro konzola (1977) |
| V.Smile CD | `vsmile_cd` | `vsmile -cdrm` | 34 | CD verzia V.Smile |
| V.Smile Baby | `vsmileb_cart` | `vsmileb -cart` | 23 | Detsky vzdelavaci system |
| Mattel Juice Box | `juicebox` | `juicebox -memcard` | 22 | Prenosny media prehravac s hrami |
| Milton Bradley Microvision | `microvision` | `microvsn -cart` | 18 | Prvy handheld s vymenitel. kartridmi (1979) |
| Bandai Pocket Challenge W | `pockchalw` | `pockchal -cart` | 40 | WonderSwan predchodca |
| Nintendo Famicom Box | `famibox` | `famibox` | 39 | Hotelovy NES automat |
| NUON | `nuon` | `n501 -cdrm` | 8 | Samsung DVD prehravac s hrami (2000) |
| Mattel HyperScan | `hyperscan` + `hyperscan_card` | `hyprscan -cart` | 7+445 | RFID kartove hry (2006) |

## Nove europske a sovietske pocitace

| System | Software list | MAME driver | Titulov | Poznamka |
|--------|--------------|-------------|---------|----------|
| MicroBee | `mbee_flop` + `mbee_quik` + `mbee_cart` | `mbee -flop1` / `-quik` / `-cart` | 717 | Australsky pocitac, velmi velka kniznica |
| Compucolor II | `compclr2_flop` | `compclr2 -flop1` | 239 | Americky pocitac |
| Olivetti Prodest PC 128 | `pro128_cass` + `pro128_flop` + `pro128s_flop` | `pro128 -cass` / `-flop1` | 202 | Taliansky pocitac |
| Robotron KC 85 | `kc_cass` + `kc_cart` + `kc_flop` | `kc85_4 -cass` / `-cart` / `-flop1` | 189 | Vychodonemecky pocitac |
| Specialist | `special_cass` | `special -cass` | 160 | Sovietsky pocitac |
| Z80-NE | `z80ne_cass` + `z80ne_flop` | `z80ne -cass` / `-flop1` | 120 | Taliansky edukacny pocitac |
| Orion 128 (kazety) | `orion_cass` | `orion128 -cass` | 82 | Doplnok k existujucim disketam |
| Nascom | `nascom_snap` + `nascom_flop` | `nascom2 -snap` / `-flop1` | 78 | Britsky pocitac |
| Partner-01.01 | `partner_cass` + `partner_flop` | `partner -cass` / `-flop1` | 75 | Sovietsky pocitac |
| Philips VG-5000 | `vg5k` | `vg5k -cass` | 68 | Francuzsky pocitac |
| Orao | `orao` | `orao -cass` | 56 | Juhoslovensky (chorvatsky) pocitac |
| Cambridge Z88 | `z88_cart` | `z88 -cart` | 31 | Prenosny pocitac od tvorcu ZX Spectrum |
| Exel EXL 100 | `exl100` | `exl100 -cart` | 16 | Francuzsky pocitac |
| Pegasus | `pegasus_cart` | `pegasus -cart` | 16 | Polsky pocitac |
| Korvet | `korvet_flop` | `korvet -flop1` | 16 | Sovietsky pocitac |
| ABC 80 | `abc80_flop` + `abc80_cass` + `abc80_rom` | `abc80 -flop1` | 18 | Svedsky pocitac |
| Juku | `juku` | `juku -flop` | 7 | Estonsky pocitac |

## Nove japonske pocitace

| System | Software list | MAME driver | Titulov | Poznamka |
|--------|--------------|-------------|---------|----------|
| Canon X-07 | `x07_cass` | `x07 -cass` | 87 | Prenosny pocitac s hrami |
| NEC PC-88VA | `pc88va` | `pc88va -flop1` | 67 | 16-bitovy PC-8801 |
| NEC APC | `apc` | `apc -flop1` | 32 | NEC Advanced Personal Computer |
| Tomy Kiss-Site | `kisssite_cd` | `kisssite -cdrm` | 30 | Japonsky detsky system |

## Nove americke/business pocitace

| System | Software list | MAME driver | Titulov | Poznamka |
|--------|--------------|-------------|---------|----------|
| Zorba | `zorba` | `zorba -flop1` | 38 | CP/M pocitac |
| Osborne 1 | `osborne1` | `osborne1 -flop1` | 22 | Ikonicky prenosny CP/M pocitac |
| Kaypro | `kaypro` | `kaypro2x -flop1` | 18 | CP/M pocitac |
| Tandy TRS-80 Model II | `trs80m2` | `trs80m2 -flop1` | 10 | Doplnok k existujucemu TRS-80 |

## Vzdelavacie a detske systemy

| System | Software list | MAME driver | Titulov | Poznamka |
|--------|--------------|-------------|---------|----------|
| e-kara | `ekara_cart` | `ekara -cart` | 242 | Japonsky karaoke system pre deti |
| LeapFrog Leapster | `leapster` | `leapster -cart` | 135 | Detsky herny system |
| LeapFrog LeapPad | `leapfrog_leappad_cart` | `leappad -cart` | 107 | Detsky vzdelavaci tablet |
| CHIP-8 | `chip8_quik` | `chip8 -quik` | 71 | Virtualny pocitac/interpret |
| VideoArt | `videoart` | `videoart -cart` | 9 | Kreslenie cez TV |

## Doplnky k existujucim systemom v platforms.csv

| Existujuci system | Chybajuci software list | MAME driver | Titulov | Poznamka |
|-------------------|------------------------|-------------|---------|----------|
| GBA | `gba_ereader` | `gba -cart` | 686 | Nintendo e-Reader karty |
| IBM PC AT | `ibm5170_cdrom` | `ibm5170 -cdrom` | 476 | CD-ROM hry |
| SNES/Satellaview | `snes_bspack` | `snes -cart` | 401 | BS-X data packs |
| APF M-1000 | `apfimag_cass` | `apfimag -cass` | 103 | Kazetove hry Imagination Machine |
| PC-8801 | `pc8801_cass` | `pc8801 -cass` | 102 | Kazetove hry |
| MSX TurboR | `msxr_flop` + `msxr_cart` | `fsa1gt -flop1` / `-cart1` | 79 | MAME softlisty |
| ZX Spectrum | `spectrum_microdrive` | `spec128 -mdrv1` | 73 | Microdrive media |
| Dragon | `dragon_os9` + `dragon_flex` + `dgnalpha_flop` | `dragon64 -flop1` | 58 | OS-9, Flex, Dragon Alpha |
| Acorn Atom | `atom_cass` | `atom -cass` | 44 | Kazetova verzia |
| V.Smile | `vsmile_cd` + `vsmileb_cart` | `vsmile -cdrm` / `vsmileb -cart` | 57 | CD + Baby verzia |
| PC-6001 | `pc6001_cass` + `pc6001mk2_cass` | `pc6001 -cass` | 34 | Kazetove verzie |
| IBM PC AT | `ibm5170_hdd` | `ibm5170 -hard` | 33 | HDD image hry |
| Amiga | `amiga_cd` | `a500 -cdrom` | 13 | CD-ROM hry |
| Macintosh | `mac_cdrom` + `mac_hdd` | `macse -cdrom` / `-hard` | 28 | CD a HDD softvery |
| Atari ST | `st_flop_demos` | `st -flop1` | 8 | Demo diskety |

---

## Zhrnutie

- **~25 uplne novych systemov** (nie su v platforms.csv vobec)
- **~15 doplnkovych software listov** k existujucim systemom
- **~3 700+ titulov** celkovo

### TOP 10 podla velkosti kniznice

1. MicroBee - 717 titulov
2. GBA e-Reader - 686 titulov (doplnok)
3. IBM PC AT CD-ROM - 476 titulov (doplnok)
4. SNES BS-X - 401 titulov (doplnok)
5. e-kara - 242 titulov
6. Compucolor II - 239 titulov
7. Olivetti Prodest PC 128 - 202 titulov
8. Robotron KC 85 - 189 titulov
9. Specialist - 160 titulov
10. LeapFrog Leapster - 135 titulov
