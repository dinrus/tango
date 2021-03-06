﻿/*******************************************************************************

        copyright:      Copyright (c) 2006 Dinrus. все rights reserved

        license:        BSD стиль: see doc/license.txt for details

        version:        Initial release: Feb 2006

        author:         Regan Heath, Oskar Linde

        This module реализует the MD4 Message Дайджест Algorithm as described 
        by RFC 1320 The MD4 Message-Дайджест Algorithm. R. Rivest. April 1992.

*******************************************************************************/

module util.digest.Md4;

public  import util.digest.Digest;

private import util.digest.MerkleDamgard;

/*******************************************************************************

*******************************************************************************/

class Md4 : MerkleDamgard
{
        protected бцел[4]       контекст;
        private const ббайт     padChar = 0x80;

        /***********************************************************************

                Construct an Md4

        ***********************************************************************/

        this() { }

        /***********************************************************************

                The MD 4 дайджест размер is 16 байты
 
        ***********************************************************************/

        бцел размерДайджеста() { return 16; }
            
        /***********************************************************************

                Initialize the cipher

                Remarks:
                Returns the cipher состояние в_ it's начальное значение

        ***********************************************************************/

        override проц сбрось()
        {
                super.сбрось();
                контекст[] = начальное[];
        }

        /***********************************************************************

                Obtain the дайджест

                Возвращает:
                the дайджест

                Remarks:
                Returns a дайджест of the текущ cipher состояние, this may be the
                final дайджест, or a дайджест of the состояние between calls в_ обнови()

        ***********************************************************************/

        override проц создайДайджест(ббайт[] буф)
        {
                version (БигЭндиан)
                         ПерестановкаБайт.своп32 (контекст.ptr, контекст.length * бцел.sizeof);

                буф[] = cast(ббайт[]) контекст;
        }

        /***********************************************************************

                 блок размер

                Возвращает:
                the блок размер

                Remarks:
                Specifies the размер (in байты) of the блок of данные в_ пароль в_
                each вызов в_ трансформируй(). For MD4 the размерБлока is 64.

        ***********************************************************************/

        protected override бцел размерБлока() { return 64; }

        /***********************************************************************

                Length паддинг размер

                Возвращает:
                the length паддинг размер

                Remarks:
                Specifies the размер (in байты) of the паддинг which uses the
                length of the данные which имеется been ciphered, this паддинг is
                carried out by the padLength метод. For MD4 the добавьРазмер is 8.

        ***********************************************************************/

        protected override бцел добавьРазмер()   { return 8;  }

        /***********************************************************************

                Pads the cipher данные

                Параметры:
                данные = a срез of the cipher буфер в_ заполни with паддинг

                Remarks:
                Fills the passed буфер срез with the appropriate паддинг for
                the final вызов в_ трансформируй(). This паддинг will заполни the cipher
                буфер up в_ размерБлока()-добавьРазмер().

        ***********************************************************************/

        protected override проц padMessage(ббайт[] данные)
        {
                данные[0] = padChar;
                данные[1..$] = 0;
        }

        /***********************************************************************

                Performs the length паддинг

                Параметры:
                данные   = the срез of the cipher буфер в_ заполни with паддинг
                length = the length of the данные which имеется been ciphered

                Remarks:
                Fills the passed буфер срез with добавьРазмер() байты of паддинг
                based on the length in байты of the ввод данные which имеется been
                ciphered.

        ***********************************************************************/

        protected override проц padLength(ббайт[] данные, бдол length)
        {
                length <<= 3;
                littleEndian64((cast(ббайт*)&length)[0..8],cast(бдол[]) данные); 
        }   

        /***********************************************************************

                Performs the cipher on a блок of данные

                Параметры:
                данные = the блок of данные в_ cipher

                Remarks:
                The actual cipher algorithm is carried out by this метод on
                the passed блок of данные. This метод is called for every
                размерБлока() байты of ввод данные и once ещё with the остаток
                данные псеп_в_конце в_ размерБлока().

        ***********************************************************************/

        protected override проц трансформируй(ббайт[] ввод)
        {
                бцел a,b,c,d;
                бцел[16] x;

                littleEndian32(ввод,x);

                a = контекст[0];
                b = контекст[1];
                c = контекст[2];
                d = контекст[3];

                /* Round 1 */
                ff(a, b, c, d, x[ 0], S11, 0); /* 1 */
                ff(d, a, b, c, x[ 1], S12, 0); /* 2 */
                ff(c, d, a, b, x[ 2], S13, 0); /* 3 */
                ff(b, c, d, a, x[ 3], S14, 0); /* 4 */
                ff(a, b, c, d, x[ 4], S11, 0); /* 5 */
                ff(d, a, b, c, x[ 5], S12, 0); /* 6 */
                ff(c, d, a, b, x[ 6], S13, 0); /* 7 */
                ff(b, c, d, a, x[ 7], S14, 0); /* 8 */
                ff(a, b, c, d, x[ 8], S11, 0); /* 9 */
                ff(d, a, b, c, x[ 9], S12, 0); /* 10 */
                ff(c, d, a, b, x[10], S13, 0); /* 11 */
                ff(b, c, d, a, x[11], S14, 0); /* 12 */
                ff(a, b, c, d, x[12], S11, 0); /* 13 */
                ff(d, a, b, c, x[13], S12, 0); /* 14 */
                ff(c, d, a, b, x[14], S13, 0); /* 15 */
                ff(b, c, d, a, x[15], S14, 0); /* 16 */

                /* Round 2 */
                gg(a, b, c, d, x[ 0], S21, 0x5a827999); /* 17 */
                gg(d, a, b, c, x[ 4], S22, 0x5a827999); /* 18 */
                gg(c, d, a, b, x[ 8], S23, 0x5a827999); /* 19 */
                gg(b, c, d, a, x[12], S24, 0x5a827999); /* 20 */
                gg(a, b, c, d, x[ 1], S21, 0x5a827999); /* 21 */
                gg(d, a, b, c, x[ 5], S22, 0x5a827999); /* 22 */
                gg(c, d, a, b, x[ 9], S23, 0x5a827999); /* 23 */
                gg(b, c, d, a, x[13], S24, 0x5a827999); /* 24 */
                gg(a, b, c, d, x[ 2], S21, 0x5a827999); /* 25 */
                gg(d, a, b, c, x[ 6], S22, 0x5a827999); /* 26 */
                gg(c, d, a, b, x[10], S23, 0x5a827999); /* 27 */
                gg(b, c, d, a, x[14], S24, 0x5a827999); /* 28 */
                gg(a, b, c, d, x[ 3], S21, 0x5a827999); /* 29 */
                gg(d, a, b, c, x[ 7], S22, 0x5a827999); /* 30 */
                gg(c, d, a, b, x[11], S23, 0x5a827999); /* 31 */
                gg(b, c, d, a, x[15], S24, 0x5a827999); /* 32 */

                /* Round 3 */
                hh(a, b, c, d, x[ 0], S31, 0x6ed9eba1); /* 33 */
                hh(d, a, b, c, x[ 8], S32, 0x6ed9eba1); /* 34 */
                hh(c, d, a, b, x[ 4], S33, 0x6ed9eba1); /* 35 */
                hh(b, c, d, a, x[12], S34, 0x6ed9eba1); /* 36 */
                hh(a, b, c, d, x[ 2], S31, 0x6ed9eba1); /* 37 */
                hh(d, a, b, c, x[10], S32, 0x6ed9eba1); /* 38 */
                hh(c, d, a, b, x[ 6], S33, 0x6ed9eba1); /* 39 */
                hh(b, c, d, a, x[14], S34, 0x6ed9eba1); /* 40 */
                hh(a, b, c, d, x[ 1], S31, 0x6ed9eba1); /* 41 */
                hh(d, a, b, c, x[ 9], S32, 0x6ed9eba1); /* 42 */
                hh(c, d, a, b, x[ 5], S33, 0x6ed9eba1); /* 43 */
                hh(b, c, d, a, x[13], S34, 0x6ed9eba1); /* 44 */
                hh(a, b, c, d, x[ 3], S31, 0x6ed9eba1); /* 45 */
                hh(d, a, b, c, x[11], S32, 0x6ed9eba1); /* 46 */
                hh(c, d, a, b, x[ 7], S33, 0x6ed9eba1); /* 47 */
                hh(b, c, d, a, x[15], S34, 0x6ed9eba1); /* 48 */

                контекст[0] += a;
                контекст[1] += b;
                контекст[2] += c;
                контекст[3] += d;

                x[] = 0;
        }

        /***********************************************************************

        ***********************************************************************/

        protected static бцел f(бцел x, бцел y, бцел z)
        {
                return (x&y)|(~x&z);
        }

        /***********************************************************************

        ***********************************************************************/

        protected static бцел h(бцел x, бцел y, бцел z)
        {
                return x^y^z;
        }

        /***********************************************************************

        ***********************************************************************/

        private static бцел g(бцел x, бцел y, бцел z)
        {
                return (x&y)|(x&z)|(y&z);
        }

        /***********************************************************************

        ***********************************************************************/

        private static проц ff(ref бцел a, бцел b, бцел c, бцел d, бцел x, бцел s, бцел ac)
        {
                a += f(b, c, d) + x + ac;
                a = вращайВлево(a, s);
        }

        /***********************************************************************

        ***********************************************************************/

        private static проц gg(ref бцел a, бцел b, бцел c, бцел d, бцел x, бцел s, бцел ac)
        {
                a += g(b, c, d) + x + ac;
                a = вращайВлево(a, s);
        }

        /***********************************************************************

        ***********************************************************************/

        private static проц hh(ref бцел a, бцел b, бцел c, бцел d, бцел x, бцел s, бцел ac)
        {
                a += h(b, c, d) + x + ac;
                a = вращайВлево(a, s);
        }

        /***********************************************************************

        ***********************************************************************/

        private static const бцел[4] начальное =
        [
                0x67452301,
                0xefcdab89,
                0x98badcfe,
                0x10325476
        ];

        /***********************************************************************

        ***********************************************************************/

        private static enum
        {
                S11 =  3,
                S12 =  7,
                S13 = 11,
                S14 = 19,
                S21 =  3,
                S22 =  5,
                S23 =  9,
                S24 = 13,
                S31 =  3,
                S32 =  9,
                S33 = 11,
                S34 = 15,
        }
}


/*******************************************************************************

*******************************************************************************/

debug(UnitTest)
{
        unittest 
        {
        static ткст[] strings = 
        [
                "",
                "a",
                "abc",
                "сообщение дайджест",
                "abcdefghijklmnopqrstuvwxyz",
                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
                "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
        ];

        static ткст[] results = 
        [
                "31d6cfe0d16ae931b73c59d7e0c089c0",
                "bde52cb31de33e46245e05fbdbd6fb24",
                "a448017aaf21d8525fc10ae87aa6729d",
                "d9130a8164549fe818874806e1c7014b",
                "d79e1c308aa5bbcdeea8ed63df412da9",
                "043f8582f241db351ce627e153e7f0e4",
                "e33b4ddc9c38f2199c3e7b164fcc0536"
        ];

        Md4 h = new Md4();

        foreach (цел i, ткст s; strings) 
                {
                h.обнови(s);
                ткст d = h.гексДайджест;
                assert(d == results[i],":("~s~")("~d~")!=("~results[i]~")");
                }
        }
}

