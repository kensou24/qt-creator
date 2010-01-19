/**************************************************************************
**
** This file is part of Qt Creator
**
** Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
**
** Contact: Nokia Corporation (qt-info@nokia.com)
**
** Commercial Usage
**
** Licensees holding valid Qt Commercial licenses may use this file in
** accordance with the Qt Commercial License Agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and Nokia.
**
** GNU Lesser General Public License Usage
**
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 2.1 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU Lesser General Public License version 2.1 requirements
** will be met: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** If you are unsure which license is appropriate for your use, please
** contact the sales department at http://qt.nokia.com/contact.
**
**************************************************************************/

#ifndef QMLJSSCANNER_H
#define QMLJSSCANNER_H

#include <qmljs/qmljs_global.h>

#include <QtCore/QList>
#include <QtCore/QSet>
#include <QtCore/QString>

namespace QmlJS {

class QMLJS_EXPORT Token
{
public:
    enum Kind {
        EndOfFile,
        Keyword,
        Identifier,
        String,
        Comment,
        Number,
        LeftParenthesis,
        RightParenthesis,
        LeftBrace,
        RightBrace,
        LeftBracket,
        RightBracket,
        Operator,
        Semicolon,
        Colon,
        Comma,
        Dot
    };

    inline Token(): offset(0), length(0), kind(EndOfFile) {}
    inline Token(int o, int l, Kind k): offset(o), length(l), kind(k) {}
    inline int begin() const { return offset; }
    inline int end() const { return offset + length; }
    inline bool is(int k) const { return k == kind; }
    inline bool isNot(int k) const { return k != kind; }

public:
    int offset;
    int length;
    Kind kind;
};

class QMLJS_EXPORT QmlJSScanner
{
public:
    QmlJSScanner();
    virtual ~QmlJSScanner();

    void setKeywords(const QSet<QString> keywords)
    { m_keywords = keywords; }

    void reset();

    QList<Token> operator()(const QString &text, int startState = 0);

    int endState() const
    { return m_endState; }

    int firstNonSpace() const
    { return m_firstNonSpace; }

    QList<Token> tokens() const
    { return m_tokens; }

private:
    void blockEnd(int state, int firstNonSpace)
    { m_endState = state; m_firstNonSpace = firstNonSpace; }
    void insertString(int start)
    { insertToken(start, 1, Token::String, false); }
    void insertComment(int start, int length)
    { insertToken(start, length, Token::Comment, false); }
    void insertCharToken(int start, const char c);
    void insertIdentifier(int start)
    { insertToken(start, 1, Token::Identifier, false); }
    void insertNumber(int start)
    { insertToken(start, 1, Token::Number, false); }
    void insertToken(int start, int length, Token::Kind kind, bool forceNewToken);
    void scanForKeywords(const QString &text);

private:
    QSet<QString> m_keywords;
    int m_endState;
    int m_firstNonSpace;
    QList<Token> m_tokens;
};

} // namespace QmlJS

#endif // QMLJSSCANNER_H
