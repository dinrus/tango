﻿/******************************************************************************

        copyright:      Copyright (c) 2009 Dinrus. все rights reserved

        license:        BSD стиль: $(LICENSE)

        version:        Jan 2010: Initial release

        author:         wm4, kris

******************************************************************************/

module core.WeakRef;

private import gc;

/******************************************************************************

        A generic СлабаяСсылка

******************************************************************************/

alias СлабаяСсылка!(Объект) СлабСсыл;

/******************************************************************************

        Implements a Weak reference. The получи() метод returns пусто once
        the объект pointed в_ есть been collected

******************************************************************************/

class СлабаяСсылка (T : Объект)
{
        public alias получи opCall;        /// alternative получи() вызов
        private ук  weakpointer;      // what the СМ gives us back

        /**********************************************************************

                initializes a weak reference

        **********************************************************************/

        this (T об)
        {
                weakpointer = смСоздайСлабУк (об);
        }

        /**********************************************************************

                clean up when we are no longer referenced

        **********************************************************************/

        ~this ()
        {
                сотри;
        }

        /**********************************************************************

                хост a different объект reference

        **********************************************************************/

        final проц установи (T об)
        {
                сотри;
                weakpointer = смСоздайСлабУк (об);
        }

        /**********************************************************************

                сотри the weak reference - получи() will always return пусто

        **********************************************************************/

        final проц сотри ()
        {
                смУдалиСлабУк (weakpointer);
                weakpointer = пусто;
        }

        /**********************************************************************

                returns the weak reference - returns пусто if the объект
                was deallocated in the meantime

        **********************************************************************/

        final T получи ()
        {
                return cast(T) смДайСлабУк (weakpointer);
        }
}


/******************************************************************************

        Note this requires -g (with dmd) in order for the СМ.collect вызов
        в_ operate as desired

******************************************************************************/

debug (СлабСсыл)
{
        import gc;

        СлабСсыл сделай ()
        {
                return new СлабСсыл (new Объект);
        }

        проц main()
        {
                auto o = new Объект;
                auto r = new СлабСсыл (o);
                assert (r() is o);
                delete o;
                assert (r() is пусто);

                auto r1 = сделай;
                assert (r1.получи);
                СМ.collect;
                assert (r1() is пусто);
        }
}