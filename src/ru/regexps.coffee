bcv_parser::regexps.space = "[\\s\\xa0]"
bcv_parser::regexps.escaped_passage = ///
	(?:^ | [^\x1f\x1e\dA-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ] )	# Beginning of string or not in the middle of a word or immediately following another book. Only count a book if it's part of a sequence: `Matt5John3` is OK, but not `1Matt5John3`
		(
			# Start inverted book/chapter (cb)
			(?:
				  (?: ch (?: apters? | a?pts?\.? | a?p?s?\.? )? \s*
					\d+ \s* (?: [\u2013\u2014\-] | through | thru | to) \s* \d+ \s*
					(?: from | of | in ) (?: \s+ the \s+ book \s+ of )?\s* )
				| (?: ch (?: apters? | a?pts?\.? | a?p?s?\.? )? \s*
					\d+ \s*
					(?: from | of | in ) (?: \s+ the \s+ book \s+ of )?\s* )
				| (?: \d+ (?: th | nd | st ) \s*
					ch (?: apter | a?pt\.? | a?p?\.? )? \s* #no plurals here since it's a single chapter
					(?: from | of | in ) (?: \s+ the \s+ book \s+ of )? \s* )
			)? # End inverted book/chapter (cb)
			\x1f(\d+)(?:/\d+)?\x1f		#book
				(?:
				    /\d+\x1f				#special Psalm chapters
				  | [\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014]
				  | надписаниях (?! [a-z] )		#could be followed by a number
				  | и#{bcv_parser::regexps.space}+далее | главы | стихи | глав | стих | гл | — | и
				  | [аб] (?! \w )			#a-e allows 1:1a
				  | $						#or the end of the string
				 )+
		)
	///gi
# These are the only valid ways to end a potential passage match. The closing parenthesis allows for fully capturing parentheses surrounding translations (ESV**)**.
bcv_parser::regexps.match_end_split = ///
	  \d+ \W* надписаниях
	| \d+ \W* и#{bcv_parser::regexps.space}+далее (?: [\s\xa0*]* \.)?
	| \d+ [\s\xa0*]* [аб] (?! \w )
	| \x1e (?: [\s\xa0*]* [)\]\uff09] )? #ff09 is a full-width closing parenthesis
	| [\d\x1f]+
	///gi
bcv_parser::regexps.control = /[\x1e\x1f]/g
bcv_parser::regexps.pre_book = "[^A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ]"

bcv_parser::regexps.first = "(?:1-?я|1-?е|1)\\.?#{bcv_parser::regexps.space}*"
bcv_parser::regexps.second = "(?:2-?я|2-?е|2)\\.?#{bcv_parser::regexps.space}*"
bcv_parser::regexps.third = "(?:3-?я|3-?е|3)\\.?#{bcv_parser::regexps.space}*"
bcv_parser::regexps.range_and = "(?:[&\u2013\u2014-]|и|—)"
bcv_parser::regexps.range_only = "(?:[\u2013\u2014-]|—)"
# Each book regexp should return two parenthesized objects: an optional preliminary character and the book itself.
bcv_parser::regexps.get_books = (include_apocrypha, case_sensitive) ->
	books = [
		osis: ["Ps"]
		apocrypha: true
		extra: "2"
		regexp: ///(\b)( # Don't match a preceding \d like usual because we only want to match a valid OSIS, which will never have a preceding digit.
			Ps151
			# Always follwed by ".1"; the regular Psalms parser can handle `Ps151` on its own.
			)(?=\.1)///g # Case-sensitive because we only want to match a valid OSIS.
	,
		osis: ["Gen"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*Бытия|Gen|Быт(?:ие)?|Нач(?:ало)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Exod"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*Исход|Exod|Исх(?:од)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Bel"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Виле[\s\xa0]*и[\s\xa0]*драконе|Bel|Бел(?:[\s\xa0]*и[\s\xa0]*Дракон|е)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Lev"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*Левит|Lev|Лев(?:ит)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Num"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*Чисел|Num|Чис(?:ла)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Sir"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Премудрост(?:и[\s\xa0]*Иисуса,[\s\xa0]*сына[\s\xa0]*Сирахова|ь[\s\xa0]*Сираха)|Ekkleziastik|Sir|Сир(?:ахова)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Wis"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Прем(?:удрости[\s\xa0]*Соломона)?|Wis)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Lam"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Плач(?:[\s\xa0]*Иеремии)?|Lam)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["EpJer"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*Иеремии|EpJer)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Rev"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Rev|Отк(?:р(?:овение)?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["PrMan"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Молитва[\s\xa0]*Манассии|PrMan)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Deut"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Deut|Втор(?:озаконие)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Josh"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*Иисуса[\s\xa0]*Навина|Josh|И(?:исус(?:а[\s\xa0]*Навина|[\s\xa0]*Навин)|еш(?:уа)?)|Нав)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Judg"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*Суде(?:[ий](?:[\s\xa0]*Израилевых)?)|Judg|Суд(?:е[ий]|ьи)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Ruth"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*Руфи|Ruth|Ру(?:т|фь?))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Esd"]
		apocrypha: true
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		(?:2(?:-?(?:[ея](?:\.[\s\xa0]*Ездры|[\s\xa0]*Ездры))|\.[\s\xa0]*Ездры|(?:[ея](?:\.[\s\xa0]*Ездры|[\s\xa0]*Ездры))|[\s\xa0]*Езд(?:ры)?)|1Esd)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Esd"]
		apocrypha: true
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		(?:3(?:-?(?:[ея](?:\.[\s\xa0]*Ездры|[\s\xa0]*Ездры))|\.[\s\xa0]*Ездры|(?:[ея](?:\.[\s\xa0]*Ездры|[\s\xa0]*Ездры))|[\s\xa0]*Езд(?:ры)?)|2Esd)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Isa"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*пророка[\s\xa0]*Исаии|Isa|Ис(?:аи[ия]?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Sam"]
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		2(?:-?(?:[ея](?:\.[\s\xa0]*(?:Книга[\s\xa0]*Царств|Самуила|Царств)|[\s\xa0]*(?:Книга[\s\xa0]*Царств|Самуила|Царств)))|\.[\s\xa0]*(?:Книга[\s\xa0]*Царств|Самуила|Царств)|(?:[ея](?:\.[\s\xa0]*(?:Книга[\s\xa0]*Царств|Самуила|Царств)|[\s\xa0]*(?:Книга[\s\xa0]*Царств|Самуила|Царств)))|[\s\xa0]*(?:Книга[\s\xa0]*Царств|Самуила|Цар(?:ств)?)|Sam)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Sam"]
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		1(?:-?(?:[ея](?:\.[\s\xa0]*(?:Книга[\s\xa0]*Царств|Самуила|Царств)|[\s\xa0]*(?:Книга[\s\xa0]*Царств|Самуила|Царств)))|\.[\s\xa0]*(?:Книга[\s\xa0]*Царств|Самуила|Царств)|(?:[ея](?:\.[\s\xa0]*(?:Книга[\s\xa0]*Царств|Самуила|Царств)|[\s\xa0]*(?:Книга[\s\xa0]*Царств|Самуила|Царств)))|[\s\xa0]*(?:Книга[\s\xa0]*Царств|Самуила|Цар(?:ств)?)|Sam)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Kgs"]
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		(?:4(?:-?(?:[ея](?:\.[\s\xa0]*(?:Книга[\s\xa0]*Царств|Царств)|[\s\xa0]*(?:Книга[\s\xa0]*Царств|Царств)))|\.[\s\xa0]*(?:Книга[\s\xa0]*Царств|Царств)|(?:[ея](?:\.[\s\xa0]*(?:Книга[\s\xa0]*Царств|Царств)|[\s\xa0]*(?:Книга[\s\xa0]*Царств|Царств)))|[\s\xa0]*(?:Книга[\s\xa0]*Царств|Цар(?:ств)?))|2(?:-?(?:[ея](?:\.[\s\xa0]*Царе[ий]|[\s\xa0]*Царе[ий]))|\.[\s\xa0]*Царе[ий]|(?:[ея](?:\.[\s\xa0]*Царе[ий]|[\s\xa0]*Царе[ий]))|[\s\xa0]*Царе[ий]|Kgs))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Kgs"]
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		(?:3(?:-?(?:[ея](?:\.[\s\xa0]*(?:Книга[\s\xa0]*Царств|Царств)|[\s\xa0]*(?:Книга[\s\xa0]*Царств|Царств)))|\.[\s\xa0]*(?:Книга[\s\xa0]*Царств|Царств)|(?:[ея](?:\.[\s\xa0]*(?:Книга[\s\xa0]*Царств|Царств)|[\s\xa0]*(?:Книга[\s\xa0]*Царств|Царств)))|[\s\xa0]*(?:Книга[\s\xa0]*Царств|Цар(?:ств)?))|1(?:-?(?:[ея](?:\.[\s\xa0]*Царе[ий]|[\s\xa0]*Царе[ий]))|\.[\s\xa0]*Царе[ий]|(?:[ея](?:\.[\s\xa0]*Царе[ий]|[\s\xa0]*Царе[ий]))|[\s\xa0]*Царе[ий]|Kgs))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Chr"]
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		2(?:-?(?:[ея](?:\.[\s\xa0]*(?:Паралипоменон|Летопись|Хроник)|[\s\xa0]*(?:Паралипоменон|Летопись|Хроник)))|\.[\s\xa0]*(?:Паралипоменон|Летопись|Хроник)|(?:[ея](?:\.[\s\xa0]*(?:Паралипоменон|Летопись|Хроник)|[\s\xa0]*(?:Паралипоменон|Летопись|Хроник)))|[\s\xa0]*(?:Хроник|Лет(?:опись)?|Пар(?:алипоменон)?)|Chr)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Chr"]
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		1(?:-?(?:[ея](?:\.[\s\xa0]*(?:Паралипоменон|Летопись|Хроник)|[\s\xa0]*(?:Паралипоменон|Летопись|Хроник)))|\.[\s\xa0]*(?:Паралипоменон|Летопись|Хроник)|(?:[ея](?:\.[\s\xa0]*(?:Паралипоменон|Летопись|Хроник)|[\s\xa0]*(?:Паралипоменон|Летопись|Хроник)))|[\s\xa0]*(?:Хроник|Лет(?:опись)?|Пар(?:алипоменон)?)|Chr)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Ezra"]
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		(?:Первая[\s\xa0]*Ездры|Книга[\s\xa0]*Ездры|1[\s\xa0]*Езд|Уза[ий]р|Ezra|Езд(?:р[аы])?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Neh"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*Неемии|Неем(?:и[ия])?|Neh)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["GkEsth"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Дополнения[\s\xa0]*к[\s\xa0]*Есфири|GkEsth)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Esth"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*Есфири|Esth|Есф(?:ирь)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Job"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*Иова|Job|Аюб|Иова?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Ps"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Заб(?:ур)?|Ps|Пс(?:ал(?:тирь|мы|ом)?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["PrAzar"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Молитва[\s\xa0]*Азария|PrAzar)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Prov"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*притче[ий][\s\xa0]*Соломоновых|Prov|Мудр(?:ые[\s\xa0]*изречения)?|Пр(?:ит(?:чи)?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Eccl"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*Екклесиаста|Eccl|Разм(?:ышления)?|Екк(?:лесиаст)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["SgThree"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Благодарственная[\s\xa0]*песнь[\s\xa0]*отроков|Молитва[\s\xa0]*святых[\s\xa0]*трех[\s\xa0]*отроков|Песнь[\s\xa0]*тр[её]х[\s\xa0]*отроков|SgThree)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Song"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Song|Песн(?:и[\s\xa0]*Песне[ий]|ь(?:[\s\xa0]*(?:песне[ий][\s\xa0]*Соломона|Суле[ий]мана))?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Jer"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*пророка[\s\xa0]*Иеремии|Jer|Иер(?:еми[ия])?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Ezek"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*пророка[\s\xa0]*Иезекииля|Ezek|Езек(?:иил)?|Иез(?:екиил[ья])?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Dan"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*пророка[\s\xa0]*Даниила|Dan|Д(?:ан(?:и(?:ила?|ял))?|он))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Hos"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*пророка[\s\xa0]*Осии|Hos|Ос(?:и[ия])?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Joel"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*пророка[\s\xa0]*Иоиля|Joel|Иоил[ья]?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Amos"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*пророка[\s\xa0]*Амоса|Amos|Ам(?:оса?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Obad"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*пророка[\s\xa0]*Авдия|Obad|Авд(?:и[ийя])?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Jonah"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*пророка[\s\xa0]*Ионы|Jonah|Ион[аы]|Юнус)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Mic"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*пророка[\s\xa0]*Михея|Mic|Мих(?:е[ийя])?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Nah"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*пророка[\s\xa0]*Наума|Наума?|Nah)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Hab"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*пророка[\s\xa0]*Аввакума|Hab|Авв(?:акума?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Zeph"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*пророка[\s\xa0]*Софонии|Zeph|Соф(?:они[ия])?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Hag"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*пророка[\s\xa0]*Аггея|Hag|Агг(?:е[ийя])?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Zech"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*пророка[\s\xa0]*Захарии|Zech|За(?:к(?:ария)?|х(?:ари[ия])?))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Mal"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*пророка[\s\xa0]*Малахии|Mal|Мал(?:ахи[ия])?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Matt"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Евангелие[\s\xa0]*от[\s\xa0]*Матфея|От[\s\xa0]*Матфея|Matt|М(?:ат(?:а[ий])?|[тф]))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Mark"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Евангелие[\s\xa0]*от[\s\xa0]*Марка|От[\s\xa0]*Марка|Mark|М(?:арк|[кр]))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Luke"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Евангелие[\s\xa0]*от[\s\xa0]*Луки|От[\s\xa0]*Луки|Luke|Л(?:ука|к))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1John"]
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		1(?:-?(?:[ея](?:\.[\s\xa0]*(?:послание[\s\xa0]*Иоанна|Ио(?:анна|хана))|[\s\xa0]*(?:послание[\s\xa0]*Иоанна|Ио(?:анна|хана))))|\.[\s\xa0]*(?:послание[\s\xa0]*Иоанна|Ио(?:анна|хана))|(?:[ея](?:\.[\s\xa0]*(?:послание[\s\xa0]*Иоанна|Ио(?:анна|хана))|[\s\xa0]*(?:послание[\s\xa0]*Иоанна|Ио(?:анна|хана))))|John|[\s\xa0]*(?:послание[\s\xa0]*Иоанна|И(?:о(?:анна|хана)|н)))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2John"]
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		2(?:-?(?:[ея](?:\.[\s\xa0]*(?:послание[\s\xa0]*Иоанна|Ио(?:анна|хана))|[\s\xa0]*(?:послание[\s\xa0]*Иоанна|Ио(?:анна|хана))))|\.[\s\xa0]*(?:послание[\s\xa0]*Иоанна|Ио(?:анна|хана))|(?:[ея](?:\.[\s\xa0]*(?:послание[\s\xa0]*Иоанна|Ио(?:анна|хана))|[\s\xa0]*(?:послание[\s\xa0]*Иоанна|Ио(?:анна|хана))))|John|[\s\xa0]*(?:послание[\s\xa0]*Иоанна|И(?:о(?:анна|хана)|н)))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["3John"]
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		3(?:-?(?:[ея](?:\.[\s\xa0]*(?:послание[\s\xa0]*Иоанна|Ио(?:анна|хана))|[\s\xa0]*(?:послание[\s\xa0]*Иоанна|Ио(?:анна|хана))))|\.[\s\xa0]*(?:послание[\s\xa0]*Иоанна|Ио(?:анна|хана))|(?:[ея](?:\.[\s\xa0]*(?:послание[\s\xa0]*Иоанна|Ио(?:анна|хана))|[\s\xa0]*(?:послание[\s\xa0]*Иоанна|Ио(?:анна|хана))))|John|[\s\xa0]*(?:послание[\s\xa0]*Иоанна|И(?:о(?:анна|хана)|н)))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["John"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Евангелие[\s\xa0]*от[\s\xa0]*Иоанна|От[\s\xa0]*Иоанна|John|И(?:охан|н))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Acts"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Acts|Деян(?:ия)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Rom"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*к[\s\xa0]*Римлянам|К[\s\xa0]*Римлянам|Rom|Рим(?:лянам)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Cor"]
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		2(?:-?(?:[ея](?:\.[\s\xa0]*(?:к[\s\xa0]*Коринфянам|Коринфянам)|[\s\xa0]*(?:к[\s\xa0]*Коринфянам|Коринфянам)))|\.[\s\xa0]*(?:к[\s\xa0]*Коринфянам|Коринфянам)|(?:[ея](?:\.[\s\xa0]*(?:к[\s\xa0]*Коринфянам|Коринфянам)|[\s\xa0]*(?:к[\s\xa0]*Коринфянам|Коринфянам)))|[\s\xa0]*(?:к[\s\xa0]*Коринфянам|Кор(?:инфянам)?)|Cor)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Cor"]
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		1(?:-?(?:[ея](?:\.[\s\xa0]*(?:к[\s\xa0]*Коринфянам|Коринфянам)|[\s\xa0]*(?:к[\s\xa0]*Коринфянам|Коринфянам)))|\.[\s\xa0]*(?:к[\s\xa0]*Коринфянам|Коринфянам)|(?:[ея](?:\.[\s\xa0]*(?:к[\s\xa0]*Коринфянам|Коринфянам)|[\s\xa0]*(?:к[\s\xa0]*Коринфянам|Коринфянам)))|[\s\xa0]*(?:к[\s\xa0]*Коринфянам|Кор(?:инфянам)?)|Cor)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Gal"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*к[\s\xa0]*Галатам|К[\s\xa0]*Галатам|Gal|Гал(?:атам)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Eph"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*к[\s\xa0]*Ефесянам|К[\s\xa0]*Ефесянам|Eph|(?:[ЕЭ]ф(?:есянам)?))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Phil"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*к[\s\xa0]*Филиппи[ий]цам|К[\s\xa0]*Филиппи[ий]цам|Phil|Ф(?:ил(?:иппи[ий]цам)?|лп))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Col"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*к[\s\xa0]*Колоссянам|Col|К(?:[\s\xa0]*Колоссянам|ол(?:оссянам)?))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Thess"]
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		2(?:-?[ея](?:\.[\s\xa0]*(?:к[\s\xa0]*Фессалоники(?:[ий]цам|Фессалоники[ий]цам)|[\s\xa0]*(?:к[\s\xa0]*Фессалоники[ий]цам|Фессалоники[ий]цам)))|\.[\s\xa0]*(?:к[\s\xa0]*Фессалоники[ий]цам|Фессалоники[ий]цам)|[ея](?:\.[\s\xa0]*(?:к[\s\xa0]*Фессалоники(?:[ий]цам|Фессалоники[ий]цам)|[\s\xa0]*(?:к[\s\xa0]*Фессалоники[ий]цам|Фессалоники[ий]цам)))|Thess|[\s\xa0]*(?:к[\s\xa0]*Фессалоники[ий]цам|Фес(?:салоники[ий]цам)?))|2(?:-?[ея](?:\.[\s\xa0]*Фессалоники(?:[ий]цам|[\s\xa0]*(?:к[\s\xa0]*Фессалоники[ий]цам|Фессалоники[ий]цам)))|[ея](?:\.[\s\xa0]*Фессалоники(?:[ий]цам|[\s\xa0]*(?:к[\s\xa0]*Фессалоники[ий]цам|Фессалоники[ий]цам))))|2(?:-?[ея][\s\xa0]*(?:к[\s\xa0]*Фессалоники(?:[ий]цам|Фессалоники[ий]цам))|[ея][\s\xa0]*(?:к[\s\xa0]*Фессалоники(?:[ий]цам|Фессалоники[ий]цам)))|2(?:-?[ея][\s\xa0]*Фессалоники(?:[ий]цам)|[ея][\s\xa0]*Фессалоники(?:[ий]цам))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Thess"]
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		1(?:-?[ея](?:\.[\s\xa0]*(?:к[\s\xa0]*Фессалоники(?:[ий]цам|Фессалоники[ий]цам)|[\s\xa0]*(?:к[\s\xa0]*Фессалоники[ий]цам|Фессалоники[ий]цам)))|\.[\s\xa0]*(?:к[\s\xa0]*Фессалоники[ий]цам|Фессалоники[ий]цам)|[ея](?:\.[\s\xa0]*(?:к[\s\xa0]*Фессалоники(?:[ий]цам|Фессалоники[ий]цам)|[\s\xa0]*(?:к[\s\xa0]*Фессалоники[ий]цам|Фессалоники[ий]цам)))|Thess|[\s\xa0]*(?:к[\s\xa0]*Фессалоники[ий]цам|Фес(?:салоники[ий]цам)?))|1(?:-?[ея](?:\.[\s\xa0]*Фессалоники(?:[ий]цам|[\s\xa0]*(?:к[\s\xa0]*Фессалоники[ий]цам|Фессалоники[ий]цам)))|[ея](?:\.[\s\xa0]*Фессалоники(?:[ий]цам|[\s\xa0]*(?:к[\s\xa0]*Фессалоники[ий]цам|Фессалоники[ий]цам))))|1(?:-?[ея][\s\xa0]*(?:к[\s\xa0]*Фессалоники(?:[ий]цам|Фессалоники[ий]цам))|[ея][\s\xa0]*(?:к[\s\xa0]*Фессалоники(?:[ий]цам|Фессалоники[ий]цам)))|1(?:-?[ея][\s\xa0]*Фессалоники(?:[ий]цам)|[ея][\s\xa0]*Фессалоники(?:[ий]цам))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Tim"]
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		2(?:-?(?:[ея](?:\.[\s\xa0]*(?:к[\s\xa0]*Тимофею|Тим(?:етею|офею))|[\s\xa0]*(?:к[\s\xa0]*Тимофею|Тим(?:етею|офею))))|\.[\s\xa0]*(?:к[\s\xa0]*Тимофею|Тим(?:етею|офею))|(?:[ея](?:\.[\s\xa0]*(?:к[\s\xa0]*Тимофею|Тим(?:етею|офею))|[\s\xa0]*(?:к[\s\xa0]*Тимофею|Тим(?:етею|офею))))|[\s\xa0]*(?:к[\s\xa0]*Тимофею|Тим(?:етею|офею)?)|Tim)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Tim"]
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		1(?:-?(?:[ея](?:\.[\s\xa0]*(?:к[\s\xa0]*Тимофею|Тим(?:етею|офею))|[\s\xa0]*(?:к[\s\xa0]*Тимофею|Тим(?:етею|офею))))|\.[\s\xa0]*(?:к[\s\xa0]*Тимофею|Тим(?:етею|офею))|(?:[ея](?:\.[\s\xa0]*(?:к[\s\xa0]*Тимофею|Тим(?:етею|офею))|[\s\xa0]*(?:к[\s\xa0]*Тимофею|Тим(?:етею|офею))))|[\s\xa0]*(?:к[\s\xa0]*Тимофею|Тим(?:етею|офею)?)|Tim)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Titus"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*к[\s\xa0]*Титу|К[\s\xa0]*Титу|Titus|Титу?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Phlm"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*к[\s\xa0]*Филимону|К[\s\xa0]*Филимону|Phlm|Ф(?:илимону|лм))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Heb"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*к[\s\xa0]*Евреям|К[\s\xa0]*Евреям|Heb|Евр(?:еям)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Jas"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*Иакова|Якуб|Jas|Иак(?:ова)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Pet"]
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		2(?:-?(?:[ея](?:\.[\s\xa0]*(?:послание[\s\xa0]*Петра|Пет(?:ира|ра))|[\s\xa0]*(?:послание[\s\xa0]*Петра|Пет(?:ира|ра))))|\.[\s\xa0]*(?:послание[\s\xa0]*Петра|Пет(?:ира|ра))|(?:[ея](?:\.[\s\xa0]*(?:послание[\s\xa0]*Петра|Пет(?:ира|ра))|[\s\xa0]*(?:послание[\s\xa0]*Петра|Пет(?:ира|ра))))|[\s\xa0]*(?:послание[\s\xa0]*Петра|Пет(?:ира|ра)?)|Pet)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Pet"]
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		1(?:-?(?:[ея](?:\.[\s\xa0]*(?:послание[\s\xa0]*Петра|Пет(?:ира|ра))|[\s\xa0]*(?:послание[\s\xa0]*Петра|Пет(?:ира|ра))))|\.[\s\xa0]*(?:послание[\s\xa0]*Петра|Пет(?:ира|ра))|(?:[ея](?:\.[\s\xa0]*(?:послание[\s\xa0]*Петра|Пет(?:ира|ра))|[\s\xa0]*(?:послание[\s\xa0]*Петра|Пет(?:ира|ра))))|[\s\xa0]*(?:послание[\s\xa0]*Петра|Пет(?:ира|ра)?)|Pet)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Jude"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*Иуды|Jude|Иуд[аы]?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Tob"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Tob|Тов(?:ита)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Jdt"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Jdt|Юди(?:фь)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Bar"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*(?:пророка[\s\xa0]*Вару́ха|Варуха)|Бару́ха|Bar|Вар(?:уха)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Sus"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:С(?:казанию[\s\xa0]*о[\s\xa0]*Сусанне[\s\xa0]*и[\s\xa0]*Данииле|усанна(?:[\s\xa0]*и[\s\xa0]*старцы)?)|Sus)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Macc"]
		apocrypha: true
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		(?:Вторая[\s\xa0]*книга[\s\xa0]*Маккаве[ий]ская|2(?:-?(?:[ея](?:\.[\s\xa0]*Маккавеев|[\s\xa0]*Маккавеев))|\.[\s\xa0]*Маккавеев|(?:[ея](?:\.[\s\xa0]*Маккавеев|[\s\xa0]*Маккавеев))|[\s\xa0]*Макк(?:авеев)?|Macc))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["3Macc"]
		apocrypha: true
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		(?:Третья[\s\xa0]*книга[\s\xa0]*Маккаве[ий]ская|3(?:-?(?:[ея](?:\.[\s\xa0]*Маккавеев|[\s\xa0]*Маккавеев))|\.[\s\xa0]*Маккавеев|(?:[ея](?:\.[\s\xa0]*Маккавеев|[\s\xa0]*Маккавеев))|[\s\xa0]*Макк(?:авеев)?|Macc))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["4Macc"]
		apocrypha: true
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		4(?:-?(?:[ея](?:\.[\s\xa0]*Маккавеев|[\s\xa0]*Маккавеев))|\.[\s\xa0]*Маккавеев|(?:[ея](?:\.[\s\xa0]*Маккавеев|[\s\xa0]*Маккавеев))|[\s\xa0]*Макк(?:авеев)?|Macc)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Macc"]
		apocrypha: true
		regexp: ///(^|[^0-9A-Za-zЀ-ҁ҃-҇Ҋ-ԧⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟ])(
		(?:Первая[\s\xa0]*книга[\s\xa0]*Маккаве[ий]ская|1(?:-?(?:[ея](?:\.[\s\xa0]*Маккавеев|[\s\xa0]*Маккавеев))|\.[\s\xa0]*Маккавеев|(?:[ея](?:\.[\s\xa0]*Маккавеев|[\s\xa0]*Маккавеев))|[\s\xa0]*Макк(?:авеев)?|Macc))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	]
	# Short-circuit the look if we know we want all the books.
	return books if include_apocrypha is true and case_sensitive is "none"
	# Filter out books in the Apocrypha if we don't want them. `Array.map` isn't supported below IE9.
	out = []
	for book in books
		continue if include_apocrypha is false and book.apocrypha? and book.apocrypha is true
		if case_sensitive is "books"
			book.regexp = new RegExp book.regexp.source, "g"
		out.push book
	out

# Default to not using the Apocrypha
bcv_parser::regexps.books = bcv_parser::regexps.get_books false, "none"