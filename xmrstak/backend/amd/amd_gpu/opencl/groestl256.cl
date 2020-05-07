R"===(
/* $Id: groestl.c 260 2011-07-21 01:02:38Z tp $ */
/*
 * Groestl256
 *
 * ==========================(LICENSE BEGIN)============================
 * Copyright (c) 2014 djm34
 * Copyright (c) 2007-2010  Projet RNRT SAPHIR
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * ===========================(LICENSE END)=============================
 *
 * @author   Thomas Pornin <thomas.pornin@cryptolog.com>
 */

#define SPH_C64(x)	x
#define SPH_ROTL64(x, y)	rotate((x), (ulong)(y))


#define C64e(x)     ((SPH_C64(x) >> 56) \
                    | ((SPH_C64(x) >> 40) & SPH_C64(0x000000000000FF00)) \
                    | ((SPH_C64(x) >> 24) & SPH_C64(0x0000000000FF0000)) \
                    | ((SPH_C64(x) >>  8) & SPH_C64(0x00000000FF000000)) \
                    | ((SPH_C64(x) <<  8) & SPH_C64(0x000000FF00000000)) \
                    | ((SPH_C64(x) << 24) & SPH_C64(0x0000FF0000000000)) \
                    | ((SPH_C64(x) << 40) & SPH_C64(0x00FF000000000000)) \
                    | ((SPH_C64(x) << 56) & SPH_C64(0xFF00000000000000)))

#define B64_0(x)    ((x) & 0xFF)
#define B64_1(x)    (((x) >> 8) & 0xFF)
#define B64_2(x)    (((x) >> 16) & 0xFF)
#define B64_3(x)    (((x) >> 24) & 0xFF)
#define B64_4(x)    (((x) >> 32) & 0xFF)
#define B64_5(x)    (((x) >> 40) & 0xFF)
#define B64_6(x)    (((x) >> 48) & 0xFF)
#define B64_7(x)    ((x) >> 56)
#define R64         SPH_ROTL64
#define PC64(j, r)  ((sph_u64)((j) + (r)))
#define QC64(j, r)  (((sph_u64)(r) << 56) ^ (~((sph_u64)(j) << 56)))

static const __constant ulong T0_G[] =
{
	0xc6a597f4a5f432c6UL, 0xf884eb9784976ff8UL, 0xee99c7b099b05eeeUL, 0xf68df78c8d8c7af6UL,
	0xff0de5170d17e8ffUL, 0xd6bdb7dcbddc0ad6UL, 0xdeb1a7c8b1c816deUL, 0x915439fc54fc6d91UL,
	0x6050c0f050f09060UL, 0x0203040503050702UL, 0xcea987e0a9e02eceUL, 0x567dac877d87d156UL,
	0xe719d52b192bcce7UL, 0xb56271a662a613b5UL, 0x4de69a31e6317c4dUL, 0xec9ac3b59ab559ecUL,
	0x8f4505cf45cf408fUL, 0x1f9d3ebc9dbca31fUL, 0x894009c040c04989UL, 0xfa87ef92879268faUL,
	0xef15c53f153fd0efUL, 0xb2eb7f26eb2694b2UL, 0x8ec90740c940ce8eUL, 0xfb0bed1d0b1de6fbUL,
	0x41ec822fec2f6e41UL, 0xb3677da967a91ab3UL, 0x5ffdbe1cfd1c435fUL, 0x45ea8a25ea256045UL,
	0x23bf46dabfdaf923UL, 0x53f7a602f7025153UL, 0xe496d3a196a145e4UL, 0x9b5b2ded5bed769bUL,
	0x75c2ea5dc25d2875UL, 0xe11cd9241c24c5e1UL, 0x3dae7ae9aee9d43dUL, 0x4c6a98be6abef24cUL,
	0x6c5ad8ee5aee826cUL, 0x7e41fcc341c3bd7eUL, 0xf502f1060206f3f5UL, 0x834f1dd14fd15283UL,
	0x685cd0e45ce48c68UL, 0x51f4a207f4075651UL, 0xd134b95c345c8dd1UL, 0xf908e9180818e1f9UL,
	0xe293dfae93ae4ce2UL, 0xab734d9573953eabUL, 0x6253c4f553f59762UL, 0x2a3f54413f416b2aUL,
	0x080c10140c141c08UL, 0x955231f652f66395UL, 0x46658caf65afe946UL, 0x9d5e21e25ee27f9dUL,
	0x3028607828784830UL, 0x37a16ef8a1f8cf37UL, 0x0a0f14110f111b0aUL, 0x2fb55ec4b5c4eb2fUL,
	0x0e091c1b091b150eUL, 0x2436485a365a7e24UL, 0x1b9b36b69bb6ad1bUL, 0xdf3da5473d4798dfUL,
	0xcd26816a266aa7cdUL, 0x4e699cbb69bbf54eUL, 0x7fcdfe4ccd4c337fUL, 0xea9fcfba9fba50eaUL,
	0x121b242d1b2d3f12UL, 0x1d9e3ab99eb9a41dUL, 0x5874b09c749cc458UL, 0x342e68722e724634UL,
	0x362d6c772d774136UL, 0xdcb2a3cdb2cd11dcUL, 0xb4ee7329ee299db4UL, 0x5bfbb616fb164d5bUL,
	0xa4f65301f601a5a4UL, 0x764decd74dd7a176UL, 0xb76175a361a314b7UL, 0x7dcefa49ce49347dUL,
	0x527ba48d7b8ddf52UL, 0xdd3ea1423e429fddUL, 0x5e71bc937193cd5eUL, 0x139726a297a2b113UL,
	0xa6f55704f504a2a6UL, 0xb96869b868b801b9UL, 0x0000000000000000UL, 0xc12c99742c74b5c1UL,
	0x406080a060a0e040UL, 0xe31fdd211f21c2e3UL, 0x79c8f243c8433a79UL, 0xb6ed772ced2c9ab6UL,
	0xd4beb3d9bed90dd4UL, 0x8d4601ca46ca478dUL, 0x67d9ce70d9701767UL, 0x724be4dd4bddaf72UL,
	0x94de3379de79ed94UL, 0x98d42b67d467ff98UL, 0xb0e87b23e82393b0UL, 0x854a11de4ade5b85UL,
	0xbb6b6dbd6bbd06bbUL, 0xc52a917e2a7ebbc5UL, 0x4fe59e34e5347b4fUL, 0xed16c13a163ad7edUL,
	0x86c51754c554d286UL, 0x9ad72f62d762f89aUL, 0x6655ccff55ff9966UL, 0x119422a794a7b611UL,
	0x8acf0f4acf4ac08aUL, 0xe910c9301030d9e9UL, 0x0406080a060a0e04UL, 0xfe81e798819866feUL,
	0xa0f05b0bf00baba0UL, 0x7844f0cc44ccb478UL, 0x25ba4ad5bad5f025UL, 0x4be3963ee33e754bUL,
	0xa2f35f0ef30eaca2UL, 0x5dfeba19fe19445dUL, 0x80c01b5bc05bdb80UL, 0x058a0a858a858005UL,
	0x3fad7eecadecd33fUL, 0x21bc42dfbcdffe21UL, 0x7048e0d848d8a870UL, 0xf104f90c040cfdf1UL,
	0x63dfc67adf7a1963UL, 0x77c1ee58c1582f77UL, 0xaf75459f759f30afUL, 0x426384a563a5e742UL,
	0x2030405030507020UL, 0xe51ad12e1a2ecbe5UL, 0xfd0ee1120e12effdUL, 0xbf6d65b76db708bfUL,
	0x814c19d44cd45581UL, 0x1814303c143c2418UL, 0x26354c5f355f7926UL, 0xc32f9d712f71b2c3UL,
	0xbee16738e13886beUL, 0x35a26afda2fdc835UL, 0x88cc0b4fcc4fc788UL, 0x2e395c4b394b652eUL,
	0x93573df957f96a93UL, 0x55f2aa0df20d5855UL, 0xfc82e39d829d61fcUL, 0x7a47f4c947c9b37aUL,
	0xc8ac8befacef27c8UL, 0xbae76f32e73288baUL, 0x322b647d2b7d4f32UL, 0xe695d7a495a442e6UL,
	0xc0a09bfba0fb3bc0UL, 0x199832b398b3aa19UL, 0x9ed12768d168f69eUL, 0xa37f5d817f8122a3UL,
	0x446688aa66aaee44UL, 0x547ea8827e82d654UL, 0x3bab76e6abe6dd3bUL, 0x0b83169e839e950bUL,
	0x8cca0345ca45c98cUL, 0xc729957b297bbcc7UL, 0x6bd3d66ed36e056bUL, 0x283c50443c446c28UL,
	0xa779558b798b2ca7UL, 0xbce2633de23d81bcUL, 0x161d2c271d273116UL, 0xad76419a769a37adUL,
	0xdb3bad4d3b4d96dbUL, 0x6456c8fa56fa9e64UL, 0x744ee8d24ed2a674UL, 0x141e28221e223614UL,
	0x92db3f76db76e492UL, 0x0c0a181e0a1e120cUL, 0x486c90b46cb4fc48UL, 0xb8e46b37e4378fb8UL,
	0x9f5d25e75de7789fUL, 0xbd6e61b26eb20fbdUL, 0x43ef862aef2a6943UL, 0xc4a693f1a6f135c4UL,
	0x39a872e3a8e3da39UL, 0x31a462f7a4f7c631UL, 0xd337bd5937598ad3UL, 0xf28bff868b8674f2UL,
	0xd532b156325683d5UL, 0x8b430dc543c54e8bUL, 0x6e59dceb59eb856eUL, 0xdab7afc2b7c218daUL,
	0x018c028f8c8f8e01UL, 0xb16479ac64ac1db1UL, 0x9cd2236dd26df19cUL, 0x49e0923be03b7249UL,
	0xd8b4abc7b4c71fd8UL, 0xacfa4315fa15b9acUL, 0xf307fd090709faf3UL, 0xcf25856f256fa0cfUL,
	0xcaaf8feaafea20caUL, 0xf48ef3898e897df4UL, 0x47e98e20e9206747UL, 0x1018202818283810UL,
	0x6fd5de64d5640b6fUL, 0xf088fb83888373f0UL, 0x4a6f94b16fb1fb4aUL, 0x5c72b8967296ca5cUL,
	0x3824706c246c5438UL, 0x57f1ae08f1085f57UL, 0x73c7e652c7522173UL, 0x975135f351f36497UL,
	0xcb238d652365aecbUL, 0xa17c59847c8425a1UL, 0xe89ccbbf9cbf57e8UL, 0x3e217c6321635d3eUL,
	0x96dd377cdd7cea96UL, 0x61dcc27fdc7f1e61UL, 0x0d861a9186919c0dUL, 0x0f851e9485949b0fUL,
	0xe090dbab90ab4be0UL, 0x7c42f8c642c6ba7cUL, 0x71c4e257c4572671UL, 0xccaa83e5aae529ccUL,
	0x90d83b73d873e390UL, 0x06050c0f050f0906UL, 0xf701f5030103f4f7UL, 0x1c12383612362a1cUL,
	0xc2a39ffea3fe3cc2UL, 0x6a5fd4e15fe18b6aUL, 0xaef94710f910beaeUL, 0x69d0d26bd06b0269UL,
	0x17912ea891a8bf17UL, 0x995829e858e87199UL, 0x3a2774692769533aUL, 0x27b94ed0b9d0f727UL,
	0xd938a948384891d9UL, 0xeb13cd351335deebUL, 0x2bb356ceb3cee52bUL, 0x2233445533557722UL,
	0xd2bbbfd6bbd604d2UL, 0xa9704990709039a9UL, 0x07890e8089808707UL, 0x33a766f2a7f2c133UL,
	0x2db65ac1b6c1ec2dUL, 0x3c22786622665a3cUL, 0x15922aad92adb815UL, 0xc92089602060a9c9UL,
	0x874915db49db5c87UL, 0xaaff4f1aff1ab0aaUL, 0x5078a0887888d850UL, 0xa57a518e7a8e2ba5UL,
	0x038f068a8f8a8903UL, 0x59f8b213f8134a59UL, 0x0980129b809b9209UL, 0x1a1734391739231aUL,
	0x65daca75da751065UL, 0xd731b553315384d7UL, 0x84c61351c651d584UL, 0xd0b8bbd3b8d303d0UL,
	0x82c31f5ec35edc82UL, 0x29b052cbb0cbe229UL, 0x5a77b4997799c35aUL, 0x1e113c3311332d1eUL,
	0x7bcbf646cb463d7bUL, 0xa8fc4b1ffc1fb7a8UL, 0x6dd6da61d6610c6dUL, 0x2c3a584e3a4e622cUL
};

)==="
	R"===(

static const __constant ulong T4_G[] =
{
	0xA5F432C6C6A597F4UL, 0x84976FF8F884EB97UL, 0x99B05EEEEE99C7B0UL, 0x8D8C7AF6F68DF78CUL,
	0x0D17E8FFFF0DE517UL, 0xBDDC0AD6D6BDB7DCUL, 0xB1C816DEDEB1A7C8UL, 0x54FC6D91915439FCUL,
	0x50F090606050C0F0UL, 0x0305070202030405UL, 0xA9E02ECECEA987E0UL, 0x7D87D156567DAC87UL,
	0x192BCCE7E719D52BUL, 0x62A613B5B56271A6UL, 0xE6317C4D4DE69A31UL, 0x9AB559ECEC9AC3B5UL,
	0x45CF408F8F4505CFUL, 0x9DBCA31F1F9D3EBCUL, 0x40C04989894009C0UL, 0x879268FAFA87EF92UL,
	0x153FD0EFEF15C53FUL, 0xEB2694B2B2EB7F26UL, 0xC940CE8E8EC90740UL, 0x0B1DE6FBFB0BED1DUL,
	0xEC2F6E4141EC822FUL, 0x67A91AB3B3677DA9UL, 0xFD1C435F5FFDBE1CUL, 0xEA25604545EA8A25UL,
	0xBFDAF92323BF46DAUL, 0xF702515353F7A602UL, 0x96A145E4E496D3A1UL, 0x5BED769B9B5B2DEDUL,
	0xC25D287575C2EA5DUL, 0x1C24C5E1E11CD924UL, 0xAEE9D43D3DAE7AE9UL, 0x6ABEF24C4C6A98BEUL,
	0x5AEE826C6C5AD8EEUL, 0x41C3BD7E7E41FCC3UL, 0x0206F3F5F502F106UL, 0x4FD15283834F1DD1UL,
	0x5CE48C68685CD0E4UL, 0xF407565151F4A207UL, 0x345C8DD1D134B95CUL, 0x0818E1F9F908E918UL,
	0x93AE4CE2E293DFAEUL, 0x73953EABAB734D95UL, 0x53F597626253C4F5UL, 0x3F416B2A2A3F5441UL,
	0x0C141C08080C1014UL, 0x52F66395955231F6UL, 0x65AFE94646658CAFUL, 0x5EE27F9D9D5E21E2UL,
	0x2878483030286078UL, 0xA1F8CF3737A16EF8UL, 0x0F111B0A0A0F1411UL, 0xB5C4EB2F2FB55EC4UL,
	0x091B150E0E091C1BUL, 0x365A7E242436485AUL, 0x9BB6AD1B1B9B36B6UL, 0x3D4798DFDF3DA547UL,
	0x266AA7CDCD26816AUL, 0x69BBF54E4E699CBBUL, 0xCD4C337F7FCDFE4CUL, 0x9FBA50EAEA9FCFBAUL,
	0x1B2D3F12121B242DUL, 0x9EB9A41D1D9E3AB9UL, 0x749CC4585874B09CUL, 0x2E724634342E6872UL,
	0x2D774136362D6C77UL, 0xB2CD11DCDCB2A3CDUL, 0xEE299DB4B4EE7329UL, 0xFB164D5B5BFBB616UL,
	0xF601A5A4A4F65301UL, 0x4DD7A176764DECD7UL, 0x61A314B7B76175A3UL, 0xCE49347D7DCEFA49UL,
	0x7B8DDF52527BA48DUL, 0x3E429FDDDD3EA142UL, 0x7193CD5E5E71BC93UL, 0x97A2B113139726A2UL,
	0xF504A2A6A6F55704UL, 0x68B801B9B96869B8UL, 0x0000000000000000UL, 0x2C74B5C1C12C9974UL,
	0x60A0E040406080A0UL, 0x1F21C2E3E31FDD21UL, 0xC8433A7979C8F243UL, 0xED2C9AB6B6ED772CUL,
	0xBED90DD4D4BEB3D9UL, 0x46CA478D8D4601CAUL, 0xD970176767D9CE70UL, 0x4BDDAF72724BE4DDUL,
	0xDE79ED9494DE3379UL, 0xD467FF9898D42B67UL, 0xE82393B0B0E87B23UL, 0x4ADE5B85854A11DEUL,
	0x6BBD06BBBB6B6DBDUL, 0x2A7EBBC5C52A917EUL, 0xE5347B4F4FE59E34UL, 0x163AD7EDED16C13AUL,
	0xC554D28686C51754UL, 0xD762F89A9AD72F62UL, 0x55FF99666655CCFFUL, 0x94A7B611119422A7UL,
	0xCF4AC08A8ACF0F4AUL, 0x1030D9E9E910C930UL, 0x060A0E040406080AUL, 0x819866FEFE81E798UL,
	0xF00BABA0A0F05B0BUL, 0x44CCB4787844F0CCUL, 0xBAD5F02525BA4AD5UL, 0xE33E754B4BE3963EUL,
	0xF30EACA2A2F35F0EUL, 0xFE19445D5DFEBA19UL, 0xC05BDB8080C01B5BUL, 0x8A858005058A0A85UL,
	0xADECD33F3FAD7EECUL, 0xBCDFFE2121BC42DFUL, 0x48D8A8707048E0D8UL, 0x040CFDF1F104F90CUL,
	0xDF7A196363DFC67AUL, 0xC1582F7777C1EE58UL, 0x759F30AFAF75459FUL, 0x63A5E742426384A5UL,
	0x3050702020304050UL, 0x1A2ECBE5E51AD12EUL, 0x0E12EFFDFD0EE112UL, 0x6DB708BFBF6D65B7UL,
	0x4CD45581814C19D4UL, 0x143C24181814303CUL, 0x355F792626354C5FUL, 0x2F71B2C3C32F9D71UL,
	0xE13886BEBEE16738UL, 0xA2FDC83535A26AFDUL, 0xCC4FC78888CC0B4FUL, 0x394B652E2E395C4BUL,
	0x57F96A9393573DF9UL, 0xF20D585555F2AA0DUL, 0x829D61FCFC82E39DUL, 0x47C9B37A7A47F4C9UL,
	0xACEF27C8C8AC8BEFUL, 0xE73288BABAE76F32UL, 0x2B7D4F32322B647DUL, 0x95A442E6E695D7A4UL,
	0xA0FB3BC0C0A09BFBUL, 0x98B3AA19199832B3UL, 0xD168F69E9ED12768UL, 0x7F8122A3A37F5D81UL,
	0x66AAEE44446688AAUL, 0x7E82D654547EA882UL, 0xABE6DD3B3BAB76E6UL, 0x839E950B0B83169EUL,
	0xCA45C98C8CCA0345UL, 0x297BBCC7C729957BUL, 0xD36E056B6BD3D66EUL, 0x3C446C28283C5044UL,
	0x798B2CA7A779558BUL, 0xE23D81BCBCE2633DUL, 0x1D273116161D2C27UL, 0x769A37ADAD76419AUL,
	0x3B4D96DBDB3BAD4DUL, 0x56FA9E646456C8FAUL, 0x4ED2A674744EE8D2UL, 0x1E223614141E2822UL,
	0xDB76E49292DB3F76UL, 0x0A1E120C0C0A181EUL, 0x6CB4FC48486C90B4UL, 0xE4378FB8B8E46B37UL,
	0x5DE7789F9F5D25E7UL, 0x6EB20FBDBD6E61B2UL, 0xEF2A694343EF862AUL, 0xA6F135C4C4A693F1UL,
	0xA8E3DA3939A872E3UL, 0xA4F7C63131A462F7UL, 0x37598AD3D337BD59UL, 0x8B8674F2F28BFF86UL,
	0x325683D5D532B156UL, 0x43C54E8B8B430DC5UL, 0x59EB856E6E59DCEBUL, 0xB7C218DADAB7AFC2UL,
	0x8C8F8E01018C028FUL, 0x64AC1DB1B16479ACUL, 0xD26DF19C9CD2236DUL, 0xE03B724949E0923BUL,
	0xB4C71FD8D8B4ABC7UL, 0xFA15B9ACACFA4315UL, 0x0709FAF3F307FD09UL, 0x256FA0CFCF25856FUL,
	0xAFEA20CACAAF8FEAUL, 0x8E897DF4F48EF389UL, 0xE920674747E98E20UL, 0x1828381010182028UL,
	0xD5640B6F6FD5DE64UL, 0x888373F0F088FB83UL, 0x6FB1FB4A4A6F94B1UL, 0x7296CA5C5C72B896UL,
	0x246C54383824706CUL, 0xF1085F5757F1AE08UL, 0xC752217373C7E652UL, 0x51F36497975135F3UL,
	0x2365AECBCB238D65UL, 0x7C8425A1A17C5984UL, 0x9CBF57E8E89CCBBFUL, 0x21635D3E3E217C63UL,
	0xDD7CEA9696DD377CUL, 0xDC7F1E6161DCC27FUL, 0x86919C0D0D861A91UL, 0x85949B0F0F851E94UL,
	0x90AB4BE0E090DBABUL, 0x42C6BA7C7C42F8C6UL, 0xC457267171C4E257UL, 0xAAE529CCCCAA83E5UL,
	0xD873E39090D83B73UL, 0x050F090606050C0FUL, 0x0103F4F7F701F503UL, 0x12362A1C1C123836UL,
	0xA3FE3CC2C2A39FFEUL, 0x5FE18B6A6A5FD4E1UL, 0xF910BEAEAEF94710UL, 0xD06B026969D0D26BUL,
	0x91A8BF1717912EA8UL, 0x58E87199995829E8UL, 0x2769533A3A277469UL, 0xB9D0F72727B94ED0UL,
	0x384891D9D938A948UL, 0x1335DEEBEB13CD35UL, 0xB3CEE52B2BB356CEUL, 0x3355772222334455UL,
	0xBBD604D2D2BBBFD6UL, 0x709039A9A9704990UL, 0x8980870707890E80UL, 0xA7F2C13333A766F2UL,
	0xB6C1EC2D2DB65AC1UL, 0x22665A3C3C227866UL, 0x92ADB81515922AADUL, 0x2060A9C9C9208960UL,
	0x49DB5C87874915DBUL, 0xFF1AB0AAAAFF4F1AUL, 0x7888D8505078A088UL, 0x7A8E2BA5A57A518EUL,
	0x8F8A8903038F068AUL, 0xF8134A5959F8B213UL, 0x809B92090980129BUL, 0x1739231A1A173439UL,
	0xDA75106565DACA75UL, 0x315384D7D731B553UL, 0xC651D58484C61351UL, 0xB8D303D0D0B8BBD3UL,
	0xC35EDC8282C31F5EUL, 0xB0CBE22929B052CBUL, 0x7799C35A5A77B499UL, 0x11332D1E1E113C33UL,
	0xCB463D7B7BCBF646UL, 0xFC1FB7A8A8FC4B1FUL, 0xD6610C6D6DD6DA61UL, 0x3A4E622C2C3A584EUL
};

#define RSTT(d, a, b0, b1, b2, b3, b4, b5, b6, b7)   do { \
		t[d] = T0_G[B64_0(a[b0])] \
			^ R64(T0_G[B64_1(a[b1])],  8) \
			^ R64(T0_G[B64_2(a[b2])], 16) \
			^ R64(T0_G[B64_3(a[b3])], 24) \
			^ T4_G[B64_4(a[b4])] \
			^ R64(T4_G[B64_5(a[b5])],  8) \
			^ R64(T4_G[B64_6(a[b6])], 16) \
			^ R64(T4_G[B64_7(a[b7])], 24); \
		} while (0)

#define ROUND_SMALL_P(a, r)   do { \
		ulong t[8]; \
		a[0] ^= PC64(0x00, r); \
		a[1] ^= PC64(0x10, r); \
		a[2] ^= PC64(0x20, r); \
		a[3] ^= PC64(0x30, r); \
		a[4] ^= PC64(0x40, r); \
		a[5] ^= PC64(0x50, r); \
		a[6] ^= PC64(0x60, r); \
		a[7] ^= PC64(0x70, r); \
		RSTT(0, a, 0, 1, 2, 3, 4, 5, 6, 7); \
		RSTT(1, a, 1, 2, 3, 4, 5, 6, 7, 0); \
		RSTT(2, a, 2, 3, 4, 5, 6, 7, 0, 1); \
		RSTT(3, a, 3, 4, 5, 6, 7, 0, 1, 2); \
		RSTT(4, a, 4, 5, 6, 7, 0, 1, 2, 3); \
		RSTT(5, a, 5, 6, 7, 0, 1, 2, 3, 4); \
		RSTT(6, a, 6, 7, 0, 1, 2, 3, 4, 5); \
		RSTT(7, a, 7, 0, 1, 2, 3, 4, 5, 6); \
		a[0] = t[0]; \
		a[1] = t[1]; \
		a[2] = t[2]; \
		a[3] = t[3]; \
		a[4] = t[4]; \
		a[5] = t[5]; \
		a[6] = t[6]; \
		a[7] = t[7]; \
		} while (0)

#define ROUND_SMALL_Pf(a,r)   do { \
		a[0] ^= PC64(0x00, r); \
		a[1] ^= PC64(0x10, r); \
		a[2] ^= PC64(0x20, r); \
		a[3] ^= PC64(0x30, r); \
		a[4] ^= PC64(0x40, r); \
		a[5] ^= PC64(0x50, r); \
		a[6] ^= PC64(0x60, r); \
		a[7] ^= PC64(0x70, r); \
		RSTT(7, a, 7, 0, 1, 2, 3, 4, 5, 6); \
		a[7] = t[7]; \
			} while (0)

#define ROUND_SMALL_Q(a, r)   do { \
		ulong t[8]; \
		a[0] ^= QC64(0x00, r); \
		a[1] ^= QC64(0x10, r); \
		a[2] ^= QC64(0x20, r); \
		a[3] ^= QC64(0x30, r); \
		a[4] ^= QC64(0x40, r); \
		a[5] ^= QC64(0x50, r); \
		a[6] ^= QC64(0x60, r); \
		a[7] ^= QC64(0x70, r); \
		RSTT(0, a, 1, 3, 5, 7, 0, 2, 4, 6); \
		RSTT(1, a, 2, 4, 6, 0, 1, 3, 5, 7); \
		RSTT(2, a, 3, 5, 7, 1, 2, 4, 6, 0); \
		RSTT(3, a, 4, 6, 0, 2, 3, 5, 7, 1); \
		RSTT(4, a, 5, 7, 1, 3, 4, 6, 0, 2); \
		RSTT(5, a, 6, 0, 2, 4, 5, 7, 1, 3); \
		RSTT(6, a, 7, 1, 3, 5, 6, 0, 2, 4); \
		RSTT(7, a, 0, 2, 4, 6, 7, 1, 3, 5); \
		a[0] = t[0]; \
		a[1] = t[1]; \
		a[2] = t[2]; \
		a[3] = t[3]; \
		a[4] = t[4]; \
		a[5] = t[5]; \
		a[6] = t[6]; \
		a[7] = t[7]; \
		} while (0)

#define PERM_SMALL_P(a)   do { \
		for (int r = 0; r < 10; r ++) \
			ROUND_SMALL_P(a, r); \
		} while (0)

#define PERM_SMALL_Pf(a)   do { \
		for (int r = 0; r < 9; r ++) { \
			ROUND_SMALL_P(a, r);} \
            ROUND_SMALL_Pf(a,9); \
			} while (0)

#define PERM_SMALL_Q(a)   do { \
		for (int r = 0; r < 10; r ++) \
			ROUND_SMALL_Q(a, r); \
		} while (0)

)==="
