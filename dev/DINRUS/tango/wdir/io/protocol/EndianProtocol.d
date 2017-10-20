﻿/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. все rights reserved

        license:        BSD стиль: $(LICENSE)

        version:        Jan 2007 : начальное release
        
        author:         Kris 

*******************************************************************************/

module io.protocol.EndianProtocol;

private import  stdrus;

private import            io.model;

private import  io.protocol.NativeProtocol;

/*******************************************************************************

*******************************************************************************/


class ПротоколЭндиан : ПротоколНатив
{


        /***********************************************************************

        ***********************************************************************/

        this (ИПровод провод, бул префикс=да)
        {
                super (провод, префикс);
        }

        /***********************************************************************

        ***********************************************************************/

        override проц[] читай (ук приёмн, бцел байты, Тип тип)
        {
                auto возвр = super.читай (приёмн, байты, тип);

                switch (тип)
                       {
                       case Тип.Short:
                       case Тип.UShort:
                       case Тип.Utf16:
                            ПерестановкаБайт.своп16 (приёмн, байты);    
                            break;

                       case Тип.Int:
                       case Тип.UInt:
                       case Тип.Float:
                       case Тип.Utf32:
                            ПерестановкаБайт.своп32 (приёмн, байты);      
                            break;

                       case Тип.Long:
                       case Тип.ULong:
                       case Тип.Double:
                            ПерестановкаБайт.своп64 (приёмн, байты);
                            break;

                       case Тип.Real:
                            ПерестановкаБайт.своп80 (приёмн, байты);
                            break;

                       default:
                            break;
                       }

                return возвр;
        }
        
        /***********************************************************************

        ***********************************************************************/

        override проц пиши (ук ист, бцел байты, Тип тип)
        {
                alias проц function (ук приёмн, бцел байты) Swapper;
                
                проц пиши (цел маска, Swapper измени)
                {
                        т_мера писатель (проц[] приёмн)
                        {
                                // cap байты записано
                                т_мера длин = приёмн.length & маска;
                                if (длин > байты)
                                    длин = байты;

                                приёмн [0..длин] = ист [0..длин];
                                измени (приёмн.ptr, длин);
                                return длин;
                        }

                        while (байты)
                               if (байты -= buffer_.писатель (&писатель))
                                   // слей if we использован все буфер пространство
                                   buffer_.дренируй (буфер.вывод);
                }


                switch (тип)
                       {
                       case Тип.Short:
                       case Тип.UShort:
                       case Тип.Utf16:
                            пиши (~1, &ПерестановкаБайт.своп16);   
                            break;

                       case Тип.Int:
                       case Тип.UInt:
                       case Тип.Float:
                       case Тип.Utf32:
                            пиши (~3, &ПерестановкаБайт.своп32);   
                            break;

                       case Тип.Long:
                       case Тип.ULong:
                       case Тип.Double:
                            пиши (~7, &ПерестановкаБайт.своп64);   
                            break;

                       case Тип.Real:
                            пиши (~15, &ПерестановкаБайт.своп80);   
                            break;

                       default:
                            super.пиши (ист, байты, тип);
                            break;
                       }
        }
}


/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
        import io.device.Array;

        unittest
        {
                проц[] размести (ПротоколЭндиан.Читатель читатель, бцел байты, ПротоколЭндиан.Тип тип)
                {
                        return читатель ((new проц[байты]).ptr, байты, тип);
                }
        
                ткст mule;
                ткст тест = "testing testing 123";
                
                auto протокол = new ПротоколЭндиан (new Массив(32));
                протокол.пишиМассив (тест.ptr, тест.length, протокол.Тип.Utf8);
                
                mule = cast(ткст) протокол.читайМассив (mule.ptr, mule.length, протокол.Тип.Utf8, &размести);
                assert (mule == тест);

        }
}





