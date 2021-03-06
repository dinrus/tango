﻿/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. все rights reserved

        license:        BSD стиль: $(LICENSE)

        version:        Mar 2004: Initial release     
                        Dec 2006: Outback release
                        Nov 2008: relocated and simplified
                        
        author:         Kris, 
                        John Reimer, 
                        Anders F Bjorklund (Darwin patches),
                        Chris Sauls (Win95 файл support)

*******************************************************************************/

module io.device.File;

private import sys.Common, sys.WinConsts, sys.WinFuncs, sys.WinStructs: АТРИБУТЫ_БЕЗОПАСНОСТИ;

private import io.device.Device, io.device.Conduit, io.Stdout;

private import stringz, thread, exception;

/*******************************************************************************

        platform-specific functions

*******************************************************************************/

version (Win32)
         private import Utf = text.convert.Utf;
   else
      private import rt.core.stringz.posix.unistd;


/*******************************************************************************

        Implements a means of reading and writing a генерный файл. Conduits
        are the primary means of accessing external данные, and Файл
        extends the basic образец by provопрing файл-specific methods в_
        установи the файл размер, сместись в_ a specific файл позиция and so on. 
        
        Serial ввод and вывод is straightforward. In this example we
        копируй a файл directly в_ the console:
        ---
        // открой a файл for reading
        auto из_ = new Файл ("тест.txt");

        // поток directly в_ console
        Стдвыв.копируй (из_);
        ---

        And here we копируй one файл в_ другой:
        ---
        // открой файл for reading
        auto из_ = new Файл ("тест.txt");

        // открой другой for writing
        auto в_ = new Файл ("копируй.txt", Файл.ЗапСозд);

        // копируй файл and закрой
        в_.копируй.закрой;
        из_.закрой;
        ---
        
        You can use ИПотокВвода.загрузи() в_ загрузи a файл directly преобр_в память:
        ---
        auto файл = new Файл ("тест.txt");
        auto контент = файл.загрузи;
        файл.закрой;
        ---

        Or use a convenience static function внутри Файл:
        ---
        auto контент = Файл.получи ("тест.txt");
        ---

        A ещё явный version with a similar результат would be:
        ---
        // открой файл for reading
        auto файл = new Файл ("тест.txt");

        // создай an Массив в_ house the entire файл
        auto контент = new сим [файл.length];

        // читай the файл контент. Return значение is the число of байты читай
        auto байты = файл.читай (контент);
        файл.закрой;
        ---

        Conversely, one may пиши directly в_ a Файл like so:
        ---
        // открой файл for writing
        auto в_ = new Файл ("текст.txt", Файл.ЗапСозд);

        // пиши an Массив of контент в_ it
        auto байты = в_.пиши (контент);
        ---

        There are equivalent static functions, Файл.установи() and
        Файл.добавь(), which установи or добавь файл контент respectively

        Файл can happily укз random I/O. Here we use сместись() в_
        relocate the файл pointer:
        ---
        // открой a файл for reading and writing
        auto файл = new Файл ("random.bin", Файл.ЧитЗапСозд);

        // пиши some данные
        файл.пиши ("testing");

        // rewind в_ файл старт
        файл.сместись (0);

        // читай данные back again
        сим[10] врем;
        auto байты = файл.читай (врем);

        файл.закрой;
        ---

        Note that Файл is unbuffered by default - wrap an экземпляр внутри
        io.stream.Buffered for buffered I/O.

        Compile with -version=Win32SansUnicode в_ активируй Win95 & Win32s файл 
        support.
        
*******************************************************************************/



class Файл : Устройство
{


        public alias Устройство.читай  читай;
        public alias Устройство.пиши пиши;
	  //  public alias Провод.загрузи загрузи;

        /***********************************************************************
        
                Fits преобр_в 32 биты ...

        ***********************************************************************/

         align(1) struct Стиль
        {
                Доступ          доступ;                 /// права доступа
                Откр            откр;                   /// как открыть
                Общ           совместно;                  /// как в_ совместно
                Кэш           кэш;                  /// как в_ кэш
        }

        /***********************************************************************

        ***********************************************************************/

        enum Доступ : ббайт     {
                                Чит      = 0x01,       /// is читаемый
                                Зап     = 0x02,       /// is записываемый
                                ЧитЗап = 0x03,       /// Всё
                                }

        /***********************************************************************
        
        ***********************************************************************/

        enum Откр : ббайт       {
                                Сущ=0,               /// must exist
                                Созд,                 /// создай or упрости
                                Sedate,                 /// создай if necessary
                                Доб,                 /// создай if necessary
                                Нов,                    /// can't exist
                                };

        /***********************************************************************
        
        ***********************************************************************/

        enum Общ : ббайт      {
                                Нет=0,                 /// no sharing
                                Чит,                   /// shared reading
                                ЧитЗап,              /// открой for anything
                                };

        /***********************************************************************
        
        ***********************************************************************/

        enum Кэш : ббайт      {
                                Нет      = 0x00,       /// don't оптимизируй
                                Случай    = 0x01,       /// оптимизируй for random
                                Поток    = 0x02,       /// оптимизируй for поток
                                WriteThru = 0x04,       /// backing-кэш флаг
                                };

        /***********************************************************************

            Чит an existing файл
        
        ***********************************************************************/

        const Стиль ЧитСущ = {Доступ.Чит, Откр.Сущ};

        /***********************************************************************

            Чит an existing файл
        
        ***********************************************************************/

        const Стиль ЧитОбщ = {Доступ.Чит, Откр.Сущ, Общ.Чит};

        /***********************************************************************
        
                Зап on an existing файл. Do not создай

        ***********************************************************************/

        const Стиль ЗапСущ = {Доступ.Зап, Откр.Сущ};

        /***********************************************************************
        
                Зап on a clean файл. Созд if necessary

        ***********************************************************************/

        const Стиль ЗапСозд = {Доступ.Зап, Откр.Созд};

        /***********************************************************************
        
                Зап at the конец of the файл

        ***********************************************************************/

        const Стиль ЧитДоб = {Доступ.Зап, Откр.Доб};

        /***********************************************************************
        
                Чит and пиши an existing файл

        ***********************************************************************/

        const Стиль ЧитЗапСущ = {Доступ.ЧитЗап, Откр.Сущ}; 

        /***********************************************************************
        
                Чит & пиши on a clean файл. Созд if necessary

        ***********************************************************************/

        const Стиль ЧитЗапСозд = {Доступ.ЧитЗап, Откр.Созд}; 

        /***********************************************************************
        
                Чит and Зап. Use existing файл if present

        ***********************************************************************/

        const Стиль ЧитЗапОткр = {Доступ.ЧитЗап, Откр.Sedate}; 


        // the файл we're working with 
        private ткст  путь_;

        // the стиль we're opened with
        private Стиль   стиль_;

        /***********************************************************************
        
                Созд a Файл for use with открой()

                Note that Файл is unbuffered by default - wrap an экземпляр 
                внутри io.stream.Buffered for buffered I/O

        ***********************************************************************/

        this ()
        {
        }

        /***********************************************************************
        
                Созд a Файл with the provопрed путь and стиль.

                Note that Файл is unbuffered by default - wrap an экземпляр 
                внутри io.stream.Buffered for buffered I/O

        ***********************************************************************/

        this (ткст путь, Стиль стиль = ЧитСущ)
        {
                открой (путь, стиль);				
        }

        /***********************************************************************
        
                Return the Стиль used for this файл.

        ***********************************************************************/

        Стиль стиль ()
        {
                return стиль_;
        }               

        /***********************************************************************
        
                Return the путь used by this файл.

        ***********************************************************************/

        override ткст вТкст ()
        {
                return путь_;
        }               

        /***********************************************************************

                Convenience function в_ return the контент of a файл.
                Returns a срез of the provопрed вывод буфер, where
                that есть sufficient ёмкость, and allocates из_ the
                куча where the файл контент is larger.

                Content размер is determined via the файл-system, per
                Файл.length, although that may be misleading for some
                *nix systems. An alternative is в_ use Файл.загрузи which
                loads контент until an Кф is encountered

        ***********************************************************************/

        static проц[] получи (ткст путь, проц[] приёмн = пусто)
        {
                scope файл = new Файл (путь);  

                // размести enough пространство for the entire файл
                auto длин = cast(т_мера) файл.длина;
                if (приёмн.length < длин){
                    if (приёмн is пусто){ // avoопр настройка the noscan attribute, one should maybe change the return тип
                        приёмн=new ббайт[](длин);
                    } else {
                        приёмн.length = длин;
                    }
                }

                //читай the контент
                длин = файл.читай (приёмн);
                if (длин is файл.Кф)
                    throw new ВВИскл("io.device.File.Файл.читай :: неожиданный кф");

                return приёмн [0 .. длин];
        }

        /***********************************************************************

                Convenience function в_ установи файл контент and length в_ 
                reflect the given Массив

        ***********************************************************************/

        static проц установи (ткст путь, проц[] контент)
        {
                scope файл = new Файл (путь, ЧитЗапСозд);  
                файл.пиши (контент);
        }

        /***********************************************************************

                Convenience function в_ добавь контент в_ a файл

        ***********************************************************************/

        static проц добавь (ткст путь, проц[] контент)
        {
                scope файл = new Файл (путь, ЧитДоб);  
                файл.пиши (контент);
        }

        /***********************************************************************

                Windows-specific код
        
        ***********************************************************************/

        version(Win32)
        {
                /***************************************************************
                  
                    Low уровень открой for подст-classes that need в_ apply specific
                    атрибуты.

                    Return: нет in case of failure

                ***************************************************************/

                protected бул открой (ткст путь, Стиль стиль, DWORD добатр)
                {
                        DWORD   атр,
                                совместно,
                                доступ,
                                созд;

                        alias DWORD[] Флаги;

                        static const Флаги Доступ =  
                                        [
                                        0,                      // не_годится
                                        GENERIC_READ,
                                        GENERIC_WRITE,
                                        GENERIC_READ | GENERIC_WRITE,
                                        ];
                                                
                        static const Флаги Созд =  
                                        [
                                        OPEN_EXISTING,          // must exist
                                        CREATE_ALWAYS,          // упрости always
                                        OPEN_ALWAYS,            // создай if needed
                                        OPEN_ALWAYS,            // (for appending)
                                        CREATE_NEW              // can't exist
                                        ];
                                                
                        static const Флаги Общ =   
                                        [
                                        0,
                                        FILE_SHARE_READ,
                                        FILE_SHARE_READ | FILE_SHARE_WRITE,
                                        ];
                                                
                        static const Флаги Атр =   
                                        [
                                        0,
                                        FILE_FLAG_RANDOM_ACCESS,
                                        FILE_FLAG_SEQUENTIAL_SCAN,
                                        0,
                                        FILE_FLAG_WRITE_THROUGH,
                                        ];

                        // remember our settings
                        assert(путь);
                        путь_ = путь;
                        стиль_ = стиль;

                        атр   = Атр[стиль.кэш] | добатр;
                        совместно  = Общ[стиль.совместно];
                        созд = Созд[стиль.откр];
                        доступ = Доступ[стиль.доступ];

                        if (планировщик)
                            атр |= FILE_FLAG_OVERLAPPED;// + FILE_FLAG_NO_BUFFERING;

                        // zero терминируй the путь
                        сим[512] zero =void;
                        auto имя = stringz.вТкст0 (путь, zero);

                        version (Win32SansUnicode)
                                 вв.указатель = cast(Дескр) СоздайФайлА (путь, cast(ППраваДоступа) доступ, cast(ПСовмИспФайла) совместно, cast(АТРИБУТЫ_БЕЗОПАСНОСТИ)
                                                          null, cast(ПРежСоздФайла) созд, cast(ПФайл) 
                                                          (атр | FILE_ATTRIBUTE_NORMAL),
                                                          cast(ук) null);
                             else
                                {
                                // преобразуй в_ utf16
                                шим[512] преобраз =void;
                                auto wide = Utf.вТкст16 (имя[0..путь.length+1], преобраз);

                                // открой the файл
                                вв.указатель = cast(Дескр) СоздайФайл (wide, cast(ППраваДоступа) доступ, cast(ПСовмИспФайла) совместно,cast(АТРИБУТЫ_БЕЗОПАСНОСТИ*)
                                                         null, cast(ПРежСоздФайла) созд, 
                                                         cast(ПФайл) (атр | FILE_ATTRIBUTE_NORMAL),
                                                         cast(ук) null);
                                }

                        if (вв.указатель is НЕВЕРНХЭНДЛ)
						{
						//Стдвыв("Неверный ук").нс;
                            return нет;
						}

                        // сбрось extended ошибка 
                        SetLastError (ERROR_SUCCESS);

                        // перемести в_ конец of файл?
                        if (стиль.откр is Откр.Доб)
                            *(cast(дол*) &вв.асинх.смещение) = -1;
                        else
                           вв.след = да;

                        // monitor this укз for async I/O?
                        if (планировщик) планировщик.открой(cast(thread.Фибра.Планировщик.Дескр) вв.указатель, вТкст());
						{
						//Стдвыв("Планировщику - ук").нс;
                        return да;
						}
                }

                /***************************************************************

                        Откр a файл with the provопрed стиль.

                ***************************************************************/

                проц открой (ткст путь, Стиль стиль = ЧитСущ)
                {
                    if (! открой (путь, стиль, 0))
                          ошибка;
                }

                /***************************************************************

                        Набор the файл размер в_ be that of the текущ сместись 
                        позиция. The файл must be записываемый for this в_
                        succeed.

                ***************************************************************/

                проц упрости ()
                {
                        упрости (позиция);
                }               

                /***************************************************************

                        Набор the файл размер в_ be the specified length. The 
                        файл must be записываемый for this в_ succeed. 

                ***************************************************************/

                проц упрости (дол размер)
                {
                        auto s = сместись (размер);
                        assert (s is размер);

                        // must have Generic_Write доступ
                        if (! SetEndOfFile (cast(HANDLE) вв.указатель))
                              ошибка;                            
                }               

                /***************************************************************

                        Набор the файл сместись позиция в_ the specified смещение
                        из_ the given якорь. 

                ***************************************************************/

                override дол сместись (дол смещение, Якорь якорь = Якорь.Нач)
                {
                        дол новСмещение; 

                        // hack в_ ensure overlapped.Offset and файл location 
                        // are correctly in synch ...
                        if (якорь is Якорь.Тек)
                            SetFilePointerEx (cast(HANDLE) вв.указатель, 
                                              *cast(LARGE_INTEGER*) &вв.асинх.смещение, 
                                              cast(PLARGE_INTEGER) &новСмещение, 0);

                        if (! SetFilePointerEx (cast(HANDLE) вв.указатель, *cast(LARGE_INTEGER*) 
                                                &смещение, cast(PLARGE_INTEGER) 
                                                &новСмещение, якорь)) 
                              ошибка;

                        return (*cast(дол*) &вв.асинх.смещение) = новСмещение;
                } 
                              
                /***************************************************************
                
                        Return the текущ файл позиция.
                
                ***************************************************************/

                дол позиция ()
                {
                        return *cast(дол*) &вв.асинх.смещение;
                }               

                /***************************************************************
        
                        Return the total length of this файл.

                ***************************************************************/

                дол длина ()
                {
                        дол длин;

                        if (! GetFileSizeEx (cast(HANDLE) вв.указатель, cast(PLARGE_INTEGER) &длин))
                              ошибка;
                        return длин;
                }               

	        /***************************************************************

		        Instructs the OS в_ слей it's internal buffers в_ 
                        the disk устройство.

                        NOTE: due в_ OS and hardware design, данные flushed 
                        cannot be guaranteed в_ be actually on disk-platters. 
                        Actual durability of данные depends on пиши-caches, 
                        barriers, presence of battery-backup, filesystem and 
                        OS-support.

                ***************************************************************/

	        проц синх ()
	        {
                         if (! FlushFileBuffers (cast(HANDLE) вв.указатель))
                               ошибка;
                }
        }


        /***********************************************************************

                 Unix-specific код. Note that some methods are 32bit only
        
        ***********************************************************************/

        version (Posix)
        {
                /***************************************************************

                    Low уровень открой for подст-classes that need в_ apply specific
                    атрибуты.

                    Return:
                        нет in case of failure

                ***************************************************************/

                protected бул открой (ткст путь, Стиль стиль,
                                     цел добфлаги, цел доступ = 0666)
                {
                        alias цел[] Флаги;

                        const O_LARGEFILE = 0x8000;

                        static const Флаги Доступ =  
                                        [
                                        0,                      // не_годится
                                        O_RDONLY,
                                        O_WRONLY,
                                        O_RDWR,
                                        ];
                                                
                        static const Флаги Созд =  
                                        [
                                        0,                      // открой existing
                                        O_CREAT | O_TRUNC,      // упрости always
                                        O_CREAT,                // создай if needed
                                        O_APPEND | O_CREAT,     // добавь
                                        O_CREAT | O_EXCL,       // can't exist
                                        ];

                        static const крат[] Locks =   
                                        [
                                        F_WRLCK,                // no sharing
                                        F_RDLCK,                // shared читай
                                        ];
                                                
                        // remember our settings
                        assert(путь);
                        путь_ = путь;
                        стиль_ = стиль;

                        // zero терминируй and преобразуй в_ utf16
                        сим[512] zero =void;
                        auto имя = stringz.вТкст0 (путь, zero);
                        auto режим = Доступ[стиль.доступ] | Созд[стиль.открой];

                        // always открой as a large файл
                        укз = posix.открой (имя, режим | O_LARGEFILE | добфлаги, 
                                             доступ);
                        if (укз is -1)
                            return нет;

                        return да;
                }

                /***************************************************************

                        Откр a файл with the provопрed стиль.

                        Note that файлы default в_ no-sharing. That is, 
                        they are locked exclusively в_ the хост process 
                        unless otherwise stИПulated. We do this in order
                        в_ expose the same default behaviour as Win32

                        NO FILE LOCKING FOR BORKED POSIX

                ***************************************************************/

                проц открой (ткст путь, Стиль стиль = ЧитСущ)
                {
                    if (! открой (путь, стиль, 0))
                          ошибка;
                }

                /***************************************************************

                        Набор the файл размер в_ be that of the текущ сместись 
                        позиция. The файл must be записываемый for this в_
                        succeed.

                ***************************************************************/

                проц упрости ()
                {
                        упрости (позиция);
                }               

                /***************************************************************

                        Набор the файл размер в_ be the specified length. The 
                        файл must be записываемый for this в_ succeed.

                ***************************************************************/

                override проц упрости (дол размер)
                {
                        // установи filesize в_ be текущ сместись-позиция
                        if (posix.ftruncate (укз, cast(off_t) размер) is -1)
                            ошибка;
                }               

                /***************************************************************

                        Набор the файл сместись позиция в_ the specified смещение
                        из_ the given якорь. 

                ***************************************************************/

                override дол сместись (дол смещение, Якорь якорь = Якорь.Нач)
                {
                        дол результат = posix.lseek (укз, cast(off_t) смещение, якорь);
                        if (результат is -1)
                            ошибка;
                        return результат;
                }               

                /***************************************************************
                
                        Return the текущ файл позиция.
                
                ***************************************************************/

                дол позиция ()
                {
                        return сместись (0, Якорь.Тек);
                }               

                /***************************************************************
        
                        Return the total length of this файл. 

                ***************************************************************/

                дол length ()
                {
                        stat_t статс =void;
                        if (posix.fstat (укз, &статс))
                            ошибка;
                        return cast(дол) статс.st_size;
                }               

	        /***************************************************************

		        Instructs the OS в_ слей it's internal buffers в_ 
                        the disk устройство.

                        NOTE: due в_ OS and hardware design, данные flushed 
                        cannot be guaranteed в_ be actually on disk-platters. 
                        Actual durability of данные depends on пиши-caches, 
                        barriers, presence of battery-backup, filesystem and 
                        OS-support.

                ***************************************************************/

	        проц синх ()
	        {
                         if (fsync (укз))
                             ошибка;
                }                            
        }
}
alias Файл ФВвод, ФВывод;

debug (File)
{
        import io.Stdout;

        проц main()
        {
                сим[10] ff;

                auto файл = new Файл("File.d");
                auto контент = cast(ткст) файл.загрузи (файл);
				Стдвыв(контент).нс;
                assert (контент.length is файл.length);		
                assert (файл.читай(ff) is файл.Кф);
		        assert (файл.позиция is контент.length);
                файл.сместись (0);
                assert (файл.позиция is 0);				
				Стдвыв("Позиция при чтении фф = ", файл.читай(ff)).нс;
                assert (файл.читай(ff) is 10);
                assert (файл.позиция is 20);
                assert (файл.сместись(0, файл.Якорь.Тек) is 20);
                assert (файл.сместись(5, файл.Якорь.Тек) is 25);
        }
}
