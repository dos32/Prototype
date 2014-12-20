--
-- PostgreSQL database dump
--

-- Dumped from database version 9.1.3
-- Dumped by pg_dump version 9.1.3
-- Started on 2014-12-20 14:06:45

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 195 (class 3079 OID 11639)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2049 (class 0 OID 0)
-- Dependencies: 195
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- TOC entry 548 (class 1247 OID 16388)
-- Dependencies: 6 169
-- Name: xx; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE xx AS (
	a bigint,
	b text
);


ALTER TYPE public.xx OWNER TO postgres;

--
-- TOC entry 207 (class 1255 OID 16389)
-- Dependencies: 622 6
-- Name: _get_config_var(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _get_config_var(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
begin
  return (select value from config where key=name);
end;$$;


ALTER FUNCTION public._get_config_var(name text) OWNER TO postgres;

--
-- TOC entry 2050 (class 0 OID 0)
-- Dependencies: 207
-- Name: FUNCTION _get_config_var(name text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION _get_config_var(name text) IS 'author Bogdan Trofimov';


--
-- TOC entry 237 (class 1255 OID 16390)
-- Dependencies: 622 6
-- Name: _svc_reset_db(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _svc_reset_db() RETURNS void
    LANGUAGE plpgsql
    AS $$begin
  truncate table tf cascade;
  truncate table doc_term cascade;
  truncate table docs cascade;
  truncate table terms cascade;
  truncate table index_queue cascade;
  truncate table neuron_doc cascade;
  truncate table neuron_neuron cascade;
  truncate table neuron_vectors cascade;
  truncate table neurons cascade;
  
  perform setval('index_queue_id_seq',1);
  perform setval('docs_id_seq',1);
  perform setval('terms_id_seq',1);
  perform setval('neurons_id_seq',1);
end;$$;


ALTER FUNCTION public._svc_reset_db() OWNER TO postgres;

--
-- TOC entry 2051 (class 0 OID 0)
-- Dependencies: 237
-- Name: FUNCTION _svc_reset_db(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION _svc_reset_db() IS 'author Bogdan Trofimov';


--
-- TOC entry 209 (class 1255 OID 16391)
-- Dependencies: 622 6
-- Name: _svc_reset_index(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _svc_reset_index() RETURNS void
    LANGUAGE plpgsql
    AS $$begin
  truncate table tf cascade;
  truncate table doc_term cascade;
  truncate table docs cascade;
  truncate table terms cascade;
  truncate table index_queue cascade;
  
  perform setval('index_queue_id_seq',1);
  perform setval('docs_id_seq',1);
  perform setval('terms_id_seq',1);
end;$$;


ALTER FUNCTION public._svc_reset_index() OWNER TO postgres;

--
-- TOC entry 2052 (class 0 OID 0)
-- Dependencies: 209
-- Name: FUNCTION _svc_reset_index(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION _svc_reset_index() IS 'author Bogdan Trofimov';


--
-- TOC entry 210 (class 1255 OID 16392)
-- Dependencies: 622 6
-- Name: _svc_reset_net(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _svc_reset_net() RETURNS void
    LANGUAGE plpgsql
    AS $$begin
  truncate table neuron_doc cascade;
  truncate table neuron_neuron cascade;
  truncate table neuron_vectors cascade;
  truncate table neurons cascade;
  
  perform setval('neurons_id_seq',1);
end;$$;


ALTER FUNCTION public._svc_reset_net() OWNER TO postgres;

--
-- TOC entry 2053 (class 0 OID 0)
-- Dependencies: 210
-- Name: FUNCTION _svc_reset_net(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION _svc_reset_net() IS 'author Bogdan Trofimov';


--
-- TOC entry 232 (class 1255 OID 570936)
-- Dependencies: 6 622
-- Name: _trained_docs_percent(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _trained_docs_percent() RETURNS numeric
    LANGUAGE plpgsql
    AS $$begin
  return (select (100.0*(select count(1) from docs d
  join neuron_doc nd
  on nd.doc_id = d.id))/
  (select count(1) from docs));
end;$$;


ALTER FUNCTION public._trained_docs_percent() OWNER TO postgres;

--
-- TOC entry 2054 (class 0 OID 0)
-- Dependencies: 232
-- Name: FUNCTION _trained_docs_percent(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION _trained_docs_percent() IS 'author Bogdan Trofimov';


--
-- TOC entry 208 (class 1255 OID 16393)
-- Dependencies: 6 622
-- Name: doc_add(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION doc_add(path text) RETURNS bigint
    LANGUAGE plpgsql
    AS $_$
declare
  iParentId bigint;
  iId bigint;
  i integer;
  sPart text;
  arrParts text[];
begin
  iParentId = 0;
  arrParts = regexp_split_to_array($1,
    _get_config_var('doc_path_delimeters'));
  i = array_lower(arrParts, 1);
  while i<=array_upper(arrParts, 1) loop
    sPart = arrParts[i];
    if(sPart <> '') then
      select * from docs where node = sPart and parent_id = iParentId into iId;
      if(iId is null) then
        insert into docs (parent_id, node, weight)
          values (iParentId, sPart, 0) returning id into iParentId;
      else
        iParentId = iId;
      end if;
    end if;
    i = i+1;
  end loop;
  return iParentId;
end;$_$;


ALTER FUNCTION public.doc_add(path text) OWNER TO postgres;

--
-- TOC entry 2055 (class 0 OID 0)
-- Dependencies: 208
-- Name: FUNCTION doc_add(path text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION doc_add(path text) IS 'author Bogdan Trofimov';


--
-- TOC entry 211 (class 1255 OID 16394)
-- Dependencies: 6 622
-- Name: doc_get_id(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION doc_get_id(path text) RETURNS bigint
    LANGUAGE plpgsql
    AS $_$
declare
  iParentId bigint;
  iId bigint;
  i integer;
  sPart text;
  arrParts text[];
begin
  iParentId = 0;
  arrParts = regexp_split_to_array($1,
    _get_config_var('doc_path_delimeters'));
  i = array_lower(arrParts, 1);
  while i<=array_upper(arrParts, 1) loop
    sPart = arrParts[i];
    if(sPart <> '') then
      select id from docs where node = sPart and parent_id = iParentId into iId;
      if(iId is null) then
        return null;
      else
        iParentId = iId;
      end if;
    end if;
    i = i+1;
  end loop;
  return iId;
end;$_$;


ALTER FUNCTION public.doc_get_id(path text) OWNER TO postgres;

--
-- TOC entry 2056 (class 0 OID 0)
-- Dependencies: 211
-- Name: FUNCTION doc_get_id(path text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION doc_get_id(path text) IS 'author Bogdan Trofimov';


--
-- TOC entry 231 (class 1255 OID 16395)
-- Dependencies: 6 622
-- Name: doc_get_path(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION doc_get_path(id bigint) RETURNS text
    LANGUAGE plpgsql
    AS $_$
declare 
  sDelim text;
begin
  sDelim = _get_config_var('doc_path_delim');
  return (with recursive a(ord, id, path) as (
        select 1, parent_id, node from docs where docs.id = $1
      union
        select a.ord+1, parent_id, node||sDelim||a.path
        from a, docs
        where docs.id = a.id
    )
    select path from a order by ord desc limit 1);
end;$_$;


ALTER FUNCTION public.doc_get_path(id bigint) OWNER TO postgres;

--
-- TOC entry 2057 (class 0 OID 0)
-- Dependencies: 231
-- Name: FUNCTION doc_get_path(id bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION doc_get_path(id bigint) IS 'author Bogdan Trofimov';


--
-- TOC entry 216 (class 1255 OID 16396)
-- Dependencies: 6 622
-- Name: doc_get_random(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION doc_get_random() RETURNS bigint
    LANGUAGE plpgsql
    AS $$begin
  return (select id from docs
    where weight>0 order by id offset floor(random() * (select count(1) from docs where weight>0)) limit 1);
end;$$;


ALTER FUNCTION public.doc_get_random() OWNER TO postgres;

--
-- TOC entry 2058 (class 0 OID 0)
-- Dependencies: 216
-- Name: FUNCTION doc_get_random(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION doc_get_random() IS 'author Bogdan Trofimov';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 170 (class 1259 OID 16397)
-- Dependencies: 6
-- Name: _vector; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE _vector (
    term_id bigint,
    value double precision
);


ALTER TABLE public._vector OWNER TO postgres;

--
-- TOC entry 217 (class 1255 OID 16400)
-- Dependencies: 622 6 552
-- Name: doc_get_vector(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION doc_get_vector(doc_id bigint) RETURNS _vector[]
    LANGUAGE plpgsql
    AS $_$begin
  return array(
    select (tf.term_id, tf.term_count)::_vector
      from tf where tf.doc_id = $1 order by term_id
  )::_vector[];
  /*return array(
    select (p2.term_id, 1.0*p2.term_count/(select weight from docs where id = $1) *
      log((select count(1) from docs)/p2.count))::_vector
    from (
      select tf1.term_id, tf1.term_count, count(1) as count from (
        select * from tf where tf.doc_id = $1 order by term_id offset $2 limit $3) tf1
      join tf tf2 on tf1.term_id = tf2.term_id
      group by tf1.term_id, tf1.term_count
    ) p2 order by p2.term_id
  )::_vector[];*/
end;$_$;


ALTER FUNCTION public.doc_get_vector(doc_id bigint) OWNER TO postgres;

--
-- TOC entry 2059 (class 0 OID 0)
-- Dependencies: 217
-- Name: FUNCTION doc_get_vector(doc_id bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION doc_get_vector(doc_id bigint) IS 'author Bogdan Trofimov';


--
-- TOC entry 212 (class 1255 OID 16401)
-- Dependencies: 6 622
-- Name: doc_remove(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION doc_remove(doc_id bigint) RETURNS bigint
    LANGUAGE plpgsql
    AS $_$
declare
  iParentId bigint;
  iId bigint;
  iResult bigint;
begin
  iResult=0;
  if(($1 is null) or ($1=0) or ((select id from docs where id = $1) is null)) then
    return iResult;
  end if;
  loop
    iParentId = $1;
    iId = $1;
    while(iId is not null)loop
      iParentId = iId;
      select id from docs where parent_id = iId into iId order by id limit 1;
    end loop;
    select doc_remove_content(iParentId);
    delete from docs where id = iParentId;
    if(iParentId = $1)then
      exit;
    else
      iResult = iResult+1;
    end if;
  end loop;
  return iResult+1;
end;$_$;


ALTER FUNCTION public.doc_remove(doc_id bigint) OWNER TO postgres;

--
-- TOC entry 2060 (class 0 OID 0)
-- Dependencies: 212
-- Name: FUNCTION doc_remove(doc_id bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION doc_remove(doc_id bigint) IS 'author Bogdan Trofimov';


--
-- TOC entry 218 (class 1255 OID 16402)
-- Dependencies: 622 6
-- Name: doc_remove_content(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION doc_remove_content(doc_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $_$
declare
  iTermId bigint;
  iTermCount integer;
  iTermCountDelta integer;
begin
  for iTermId, iTermCountDelta in
    (select term_id, term_count from tf where tf.doc_id = $1) loop
    select weight from terms where id = iTermId into iTermCount;
    update terms set weight = iTermCount - iTermCountDelta where id = iTermId;
  end loop;
  delete from tf where tf.doc_id = $1;
  delete from doc_term where doc_term.doc_id = $1;
  delete from terms where weight <= 0;
end;$_$;


ALTER FUNCTION public.doc_remove_content(doc_id bigint) OWNER TO postgres;

--
-- TOC entry 2061 (class 0 OID 0)
-- Dependencies: 218
-- Name: FUNCTION doc_remove_content(doc_id bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION doc_remove_content(doc_id bigint) IS 'author Bogdan Trofimov';


--
-- TOC entry 238 (class 1255 OID 661298)
-- Dependencies: 622 6
-- Name: fulltext_search(text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fulltext_search(query text[]) RETURNS TABLE(node text, termscnt integer)
    LANGUAGE plpgsql
    AS $$begin
  return query(select d.node, tf.term_count
      from unnest(query) q(v)
      join terms t on t.value = q.v
      join tf on tf.term_id = t.id
      join docs d on d.id = tf.doc_id
      order by tf.term_count desc);
end;$$;


ALTER FUNCTION public.fulltext_search(query text[]) OWNER TO postgres;

--
-- TOC entry 2062 (class 0 OID 0)
-- Dependencies: 238
-- Name: FUNCTION fulltext_search(query text[]); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION fulltext_search(query text[]) IS 'author Bogdan Trofimov';


--
-- TOC entry 219 (class 1255 OID 16403)
-- Dependencies: 552 6 622 552
-- Name: get_distance(_vector[], _vector[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_distance(_vector[], _vector[]) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$begin
  return (select sqrt(sum(pow(coalesce(t1.v, 0) - coalesce(t2.v, 0), 2)))
    from unnest($1) t1(i, v)
    full join unnest($2) t2(i, v)
    on t1.i = t2.i);
  /*return (select 1.0/greatest(count(1), 1e-10)
    from unnest($1) t1(i, v)
    join unnest($2) t2(i, v)
    on t1.i = t2.i);*/
end;$_$;


ALTER FUNCTION public.get_distance(_vector[], _vector[]) OWNER TO postgres;

--
-- TOC entry 2063 (class 0 OID 0)
-- Dependencies: 219
-- Name: FUNCTION get_distance(_vector[], _vector[]); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION get_distance(_vector[], _vector[]) IS 'author Bogdan Trofimov';


--
-- TOC entry 213 (class 1255 OID 16404)
-- Dependencies: 6 622
-- Name: get_neuron_doc_distance(bigint, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_neuron_doc_distance(neuron_id bigint, doc_id bigint) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$
begin
  return get_distance(doc_get_vector($2),
    array(select (term_id, value)::_vector from neuron_vectors nv where nv.neuron_id = $1)::_vector[]);
end;$_$;


ALTER FUNCTION public.get_neuron_doc_distance(neuron_id bigint, doc_id bigint) OWNER TO postgres;

--
-- TOC entry 2064 (class 0 OID 0)
-- Dependencies: 213
-- Name: FUNCTION get_neuron_doc_distance(neuron_id bigint, doc_id bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION get_neuron_doc_distance(neuron_id bigint, doc_id bigint) IS 'author Bogdan Trofimov';


--
-- TOC entry 214 (class 1255 OID 16405)
-- Dependencies: 552 6 622
-- Name: get_vector_norm(_vector[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_vector_norm(_vector[]) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$begin
  return (select sqrt(sum(pow(v,2))) from unnest($1) v(t,v));
end;$_$;


ALTER FUNCTION public.get_vector_norm(_vector[]) OWNER TO postgres;

--
-- TOC entry 2065 (class 0 OID 0)
-- Dependencies: 214
-- Name: FUNCTION get_vector_norm(_vector[]); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION get_vector_norm(_vector[]) IS 'author Bogdan Trofimov';


--
-- TOC entry 233 (class 1255 OID 661096)
-- Dependencies: 6 622
-- Name: net_search(text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION net_search(query text[]) RETURNS TABLE(node text, dst double precision)
    LANGUAGE plpgsql
    AS $$
begin
  drop table if exists d;
  create temp table d as
    select d.id
      from unnest(query) q(v)
      join terms t on t.value = q.v
      join tf on tf.term_id = t.id
      join docs d on d.id = tf.doc_id;
  drop table if exists ns;
  create temp table ns as
    select distinct n.id from neurons n
    join neuron_doc nd on nd.neuron_id = n.id
    join d on d.id = nd.doc_id;
  drop table if exists x;
  create temp table x as
    select t.id, 1.0 as v
      from unnest(query) q(v)
      join terms t on t.value = q.v;
  drop table if exists y;
  create temp table y as
    select n.id, get_distance(
      array(select (id, v)::_vector from x)::_vector[],
      array(select (nv.term_id, nv.value)::_vector from neuron_vectors nv
        where nv.neuron_id = n.id)::_vector[]
    ) as dst from ns n
    order by dst;
  return query(select docs.node, y.dst from y
    join neuron_doc nd on y.id = nd.neuron_id
    join d on d.id = nd.doc_id
    join docs on docs.id = d.id
    order by dst
    --limit 30
  );
end;$$;


ALTER FUNCTION public.net_search(query text[]) OWNER TO postgres;

--
-- TOC entry 2066 (class 0 OID 0)
-- Dependencies: 233
-- Name: FUNCTION net_search(query text[]); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION net_search(query text[]) IS 'author Bogdan Trofimov';


--
-- TOC entry 234 (class 1255 OID 16407)
-- Dependencies: 6 622
-- Name: neuron_add(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION neuron_add() RETURNS bigint
    LANGUAGE plpgsql
    AS $$
declare
  wn bigint;
  wnh bigint;
  n bigint;
  pef double precision;
begin
  wn = (select id from neurons order by error desc limit 1);
  if wn is null then raise exception 'wn is null'; end if;
  wnh = (select n.id from neurons n
    join (select neuron2_id as id from neuron_neuron
        where neuron1_id = wn or neuron2_id = wn) nn
    on n.id = nn.id
    order by error desc limit 1);
  if wnh is null then raise exception 'wnh is null'; end if;
  n = (select neuron_create(array(
    select (n1.i, (n1.v + n2.v)/2)::_vector from
        (select term_id as i, value as v from neuron_vectors where neuron_id = wn) n1
      join
        (select term_id as i, value as v from neuron_vectors where neuron_id = wnh) n2
      on n1.i = n2.i
  )::_vector[]));
  perform neuron_bind_neuron(n, wn);
  perform neuron_bind_neuron(n, wnh);
  perform neuron_unbind_neuron(wn, wnh);
  pef = (select dvalue from variables where name = 'partition_err_scale_factor');
  update neurons set error = error * pef
    where id = wn;
  update neurons set error = error * pef
    where id = wnh;
  update neurons set error = (select error from neurons where id = wn)
    where id = n;
  return n;
end;$$;


ALTER FUNCTION public.neuron_add() OWNER TO postgres;

--
-- TOC entry 2067 (class 0 OID 0)
-- Dependencies: 234
-- Name: FUNCTION neuron_add(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION neuron_add() IS 'author Bogdan Trofimov';


--
-- TOC entry 235 (class 1255 OID 16408)
-- Dependencies: 622 6
-- Name: neuron_bind_doc(bigint, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION neuron_bind_doc(neuron_id bigint, doc_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $_$
declare
  dc double precision;
begin
  if(exists(select * from neuron_doc nd where nd.neuron_id = $1 and nd.doc_id = $2)) then
    return;
  end if;
  if(exists(select * from neuron_doc nd where nd.doc_id = $2 and nd.neuron_id <> $1)) then
    perform neuron_unbind_doc((select nd.neuron_id from neuron_doc nd where nd.doc_id = $2), $2);
  end if;
  dc = 1.0*(select count(1) from neuron_doc where neuron_doc.neuron_id = $1);
  if(dc = 0)then
    delete from neuron_vectors nv where nv.neuron_id = $1;
  end if;
  drop table if exists j;
  create temp table j on commit drop as (
    select nv.term_id tn, dv.term_id td, nv.value vn, dv.value vd
    from unnest(doc_get_vector($2)) dv(term_id, value)
    full join (select * from neuron_vectors _nv where _nv.neuron_id = $1) nv
    on nv.term_id = dv.term_id);
  insert into neuron_vectors (neuron_id, term_id, value)
    select $1, dv.td, 1.0*dv.vd/(dc + 1.0) from j dv
    where dv.td is not null and dv.tn is null;
  update neuron_vectors nv
    set value = (value * dc + coalesce(dv.vd, 0.0)) / (dc + 1.0)
    from j dv
    where dv.tn is not null and
        dv.tn = nv.term_id and
        nv.neuron_id = $1;
  if((select count(1) from neuron_vectors where value = 0)>0)then
    raise exception '%;%', (select count(1) from neuron_vectors where value = 0),
      dc;
  end if;
  --delete from neuron_vectors where value = 0;
  insert into neuron_doc (neuron_id, doc_id) values ($1, $2);
  update neurons set error = error + get_neuron_doc_distance($1, $2) where id = $1;
end;$_$;


ALTER FUNCTION public.neuron_bind_doc(neuron_id bigint, doc_id bigint) OWNER TO postgres;

--
-- TOC entry 2068 (class 0 OID 0)
-- Dependencies: 235
-- Name: FUNCTION neuron_bind_doc(neuron_id bigint, doc_id bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION neuron_bind_doc(neuron_id bigint, doc_id bigint) IS 'author Bogdan Trofimov';


--
-- TOC entry 220 (class 1255 OID 16409)
-- Dependencies: 622 6
-- Name: neuron_bind_neuron(bigint, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION neuron_bind_neuron(neuron1_id bigint, neuron2_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $_$begin
  if((select count(1) from neuron_neuron nn where nn.neuron1_id = $1 and nn.neuron2_id = $2 or
    nn.neuron1_id = $2 and nn.neuron2_id = $1) = 0)
  then
    insert into neuron_neuron (neuron1_id, neuron2_id, age) values ($1, $2, 0);
  end if;
end;$_$;


ALTER FUNCTION public.neuron_bind_neuron(neuron1_id bigint, neuron2_id bigint) OWNER TO postgres;

--
-- TOC entry 2069 (class 0 OID 0)
-- Dependencies: 220
-- Name: FUNCTION neuron_bind_neuron(neuron1_id bigint, neuron2_id bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION neuron_bind_neuron(neuron1_id bigint, neuron2_id bigint) IS 'author Bogdan Trofimov';


--
-- TOC entry 221 (class 1255 OID 16410)
-- Dependencies: 552 6 622
-- Name: neuron_create(_vector[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION neuron_create(pos _vector[]) RETURNS bigint
    LANGUAGE plpgsql
    AS $_$
declare nid bigint;
begin
  insert into neurons (error) values (0) returning id into nid;
  insert into neuron_vectors (neuron_id, term_id, value)
    select nid, t.t, t.v from unnest($1) t(t, v);
  return nid;
end;$_$;


ALTER FUNCTION public.neuron_create(pos _vector[]) OWNER TO postgres;

--
-- TOC entry 2070 (class 0 OID 0)
-- Dependencies: 221
-- Name: FUNCTION neuron_create(pos _vector[]); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION neuron_create(pos _vector[]) IS 'author Bogdan Trofimov';


--
-- TOC entry 227 (class 1255 OID 16411)
-- Dependencies: 622 6
-- Name: neuron_create(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION neuron_create(doc_id bigint) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
declare nid bigint;
begin
  insert into neurons (error) values (0) returning id into nid;
  /*insert into neuron_vectors (neuron_id, term_id, value)
    select nid, t.t, t.v from unnest(doc_get_vector(doc_id)) t(t, v);*/
  perform neuron_bind_doc(nid, doc_id);
  if((select count(1) from neuron_vectors where value = 0)>0)then
    raise exception 'neu_cr err';
  end if;
  return nid;
end;$$;


ALTER FUNCTION public.neuron_create(doc_id bigint) OWNER TO postgres;

--
-- TOC entry 2071 (class 0 OID 0)
-- Dependencies: 227
-- Name: FUNCTION neuron_create(doc_id bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION neuron_create(doc_id bigint) IS 'author Bogdan Trofimov';


--
-- TOC entry 222 (class 1255 OID 16412)
-- Dependencies: 6 622
-- Name: neuron_delete(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION neuron_delete(neuron_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $_$begin
  /*drop table if exists x;
  create temp table x as (
    select doc_id from neuron_doc nd where nd.neuron_id = $1
  );*/
  delete from neuron_neuron where neuron1_id = $1 or neuron2_id = $1;
  delete from neuron_doc where neuron_doc.neuron_id = $1;
  delete from neuron_vectors where neuron_vectors.neuron_id = $1;
  delete from neurons where id = $1;
end;$_$;


ALTER FUNCTION public.neuron_delete(neuron_id bigint) OWNER TO postgres;

--
-- TOC entry 2072 (class 0 OID 0)
-- Dependencies: 222
-- Name: FUNCTION neuron_delete(neuron_id bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION neuron_delete(neuron_id bigint) IS 'author Bogdan Trofimov';


--
-- TOC entry 223 (class 1255 OID 16413)
-- Dependencies: 6 622
-- Name: neuron_inc_bond_age(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION neuron_inc_bond_age(neuron_id bigint) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$begin
  update neuron_neuron set age = age + 1
    where (neuron1_id, neuron2_id) in
      (select neuron1_id, neuron2_id from neuron_neuron where neuron1_id = $1 or neuron2_id = $1);
  delete from neuron_neuron where (neuron1_id = $1 or neuron2_id = $1)
    and age > (select ivalue from variables where name = 'max_age');
  perform neuron_delete(id) from neurons
    where (select count(1) from neuron_neuron where id = neuron1_id or id = neuron2_id) <= 0;
  return (select id from neurons where id = $1) is not null;
end;$_$;


ALTER FUNCTION public.neuron_inc_bond_age(neuron_id bigint) OWNER TO postgres;

--
-- TOC entry 2073 (class 0 OID 0)
-- Dependencies: 223
-- Name: FUNCTION neuron_inc_bond_age(neuron_id bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION neuron_inc_bond_age(neuron_id bigint) IS 'author Bogdan Trofimov';


--
-- TOC entry 224 (class 1255 OID 16414)
-- Dependencies: 6 622
-- Name: neuron_unbind_doc(bigint, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION neuron_unbind_doc(neuron_id bigint, doc_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $_$
declare
  dc double precision;
begin
  dc = 1.0*(select count(1) from neuron_doc where neuron_doc.neuron_id = $1);
  if(dc <= 1) then
    delete from neuron_vectors nv where nv.neuron_id = $1;
    delete from neuron_doc nd where nd.neuron_id = $1;
  else
    drop table if exists j;
    create temp table j on commit drop as (
      select nv.term_id tn, dv.term_id td, nv.value vn, dv.value vd
      from unnest(doc_get_vector($2)) dv(term_id, value)
      full join (select * from neuron_vectors _nv where _nv.neuron_id = $1) nv
      on nv.term_id = dv.term_id);
    insert into neuron_vectors (neuron_id, term_id, value)
      select $1, dv.td, -dv.vd/(dc - 1) from j dv
      where dv.td is not null and dv.tn is null;
    update neuron_vectors nv
      set value = (value * dc - coalesce(dv.vd, 0)) / (dc - 1)
      from j dv
      where dv.tn is not null and
        dv.tn = nv.term_id and
        nv.neuron_id = $1;
    delete from neuron_vectors where value = 0;
    delete from neuron_doc nd where nd.neuron_id = $1 and nd.doc_id = $2;
    if((select count(1) from neuron_doc nd where nd.neuron_id = $1)=0 and
      (select count(1) from neuron_vectors nv where nv.neuron_id = $1)<>0)
    then
      raise exception 'neu_unbind_doc err';
    end if;
  end if;
  --drop table j;
end;$_$;


ALTER FUNCTION public.neuron_unbind_doc(neuron_id bigint, doc_id bigint) OWNER TO postgres;

--
-- TOC entry 2074 (class 0 OID 0)
-- Dependencies: 224
-- Name: FUNCTION neuron_unbind_doc(neuron_id bigint, doc_id bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION neuron_unbind_doc(neuron_id bigint, doc_id bigint) IS 'author Bogdan Trofimov';


--
-- TOC entry 228 (class 1255 OID 16415)
-- Dependencies: 622 6
-- Name: neuron_unbind_neuron(bigint, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION neuron_unbind_neuron(bigint, bigint) RETURNS void
    LANGUAGE plpgsql
    AS $_$begin
  delete from neuron_neuron 
    where neuron1_id = $1 and neuron2_id = $2 or 
      neuron1_id = $2 and neuron2_id = $1;
end;$_$;


ALTER FUNCTION public.neuron_unbind_neuron(bigint, bigint) OWNER TO postgres;

--
-- TOC entry 2075 (class 0 OID 0)
-- Dependencies: 228
-- Name: FUNCTION neuron_unbind_neuron(bigint, bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION neuron_unbind_neuron(bigint, bigint) IS 'author Bogdan Trofimov';


--
-- TOC entry 229 (class 1255 OID 16416)
-- Dependencies: 622 6
-- Name: neurons_get_max(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION neurons_get_max() RETURNS bigint
    LANGUAGE plpgsql
    AS $$begin
  return round(pow((select count(1) from neurons), 0.67));
end;$$;


ALTER FUNCTION public.neurons_get_max() OWNER TO postgres;

--
-- TOC entry 2076 (class 0 OID 0)
-- Dependencies: 229
-- Name: FUNCTION neurons_get_max(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION neurons_get_max() IS 'author Bogdan Trofimov';


--
-- TOC entry 230 (class 1255 OID 16417)
-- Dependencies: 622 6
-- Name: queue_peek(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION queue_peek(OUT id bigint, OUT path text) RETURNS record
    LANGUAGE plpgsql
    AS $_$begin
  select id, path from index_queue order by id limit 1 into $1, $2;
end;$_$;


ALTER FUNCTION public.queue_peek(OUT id bigint, OUT path text) OWNER TO postgres;

--
-- TOC entry 2077 (class 0 OID 0)
-- Dependencies: 230
-- Name: FUNCTION queue_peek(OUT id bigint, OUT path text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION queue_peek(OUT id bigint, OUT path text) IS 'author Bogdan Trofimov';


--
-- TOC entry 225 (class 1255 OID 16418)
-- Dependencies: 622 6
-- Name: queue_push(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION queue_push(path text) RETURNS bigint
    LANGUAGE plpgsql
    AS $_$
declare iId bigint;
begin
  select id from index_queue where index_queue.path = $1 into iId;
  if(iId is null) then
    insert into index_queue (path) values ($1) returning id into iId;
  end if;
  return iId;
end;$_$;


ALTER FUNCTION public.queue_push(path text) OWNER TO postgres;

--
-- TOC entry 2078 (class 0 OID 0)
-- Dependencies: 225
-- Name: FUNCTION queue_push(path text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION queue_push(path text) IS 'author Bogdan Trofimov';


--
-- TOC entry 226 (class 1255 OID 16419)
-- Dependencies: 622 6
-- Name: queue_remove(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION queue_remove(id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $_$begin
  delete from index_queue where id = $1;
end;$_$;


ALTER FUNCTION public.queue_remove(id bigint) OWNER TO postgres;

--
-- TOC entry 2079 (class 0 OID 0)
-- Dependencies: 226
-- Name: FUNCTION queue_remove(id bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION queue_remove(id bigint) IS 'author Bogdan Trofimov';


--
-- TOC entry 215 (class 1255 OID 16420)
-- Dependencies: 6 622
-- Name: term_add(text, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION term_add(term text, doc_id bigint) RETURNS bigint
    LANGUAGE plpgsql
    AS $_$
declare iTermId bigint;
declare iWeight integer;
declare iNewSeqNo integer;
declare iTermCount integer;
begin
  select id, weight from terms where value = $1 into iTermId, iWeight;
  if(iTermId is null) then
    insert into terms(value, weight) values ($1, 1) returning id into iTermId;
  else
    update terms set weight = iWeight+1 where id = iTermId;
  end if;
  select max(seq_no) from doc_term
    where doc_term.doc_id = $2 and term_id = iTermId into iNewSeqNo;
  if(iNewSeqNo is null) then
    insert into doc_term(doc_id, term_id, seq_no) values ($2, iTermId, 0);
  else
    insert into doc_term(doc_id, term_id, seq_no)
      values (doc_id, iTermId, iNewSeqNo+1);
  end if;
  select term_count from tf where tf.doc_id = $2 and term_id = iTermId
    into iTermCount;
  if(iTermCount is null) then
    insert into tf(doc_id, term_id, term_count) values ($2, iTermId, 1);
  else
    update tf set term_count = iTermCount+1
      where tf.doc_id = $2 and term_id = iTermId;
  end if;
  return iTermId;
end;$_$;


ALTER FUNCTION public.term_add(term text, doc_id bigint) OWNER TO postgres;

--
-- TOC entry 2080 (class 0 OID 0)
-- Dependencies: 215
-- Name: FUNCTION term_add(term text, doc_id bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION term_add(term text, doc_id bigint) IS 'author Bogdan Trofimov';


--
-- TOC entry 236 (class 1255 OID 16421)
-- Dependencies: 622 6
-- Name: terms_add(text[], bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION terms_add(text[], bigint) RETURNS bigint[]
    LANGUAGE plpgsql
    AS $_$begin
  drop table if exists _x;
  drop table if exists _added;
  drop table if exists _notadded;
  create table _x as
    select terms.id, p.value, count from (
      select value, count(1) as count from unnest($1) p(value) group by value
    ) as p
    left join terms on p.value = terms.value;
  create table _added as select id, value, count from _x where id is not null;
  create table _notadded as select id, value, count from _x where id is null;
  create index _notadded_value_idx on _notadded using btree (value COLLATE pg_catalog."default" );
  create index _added_value_idx on _added using btree (value COLLATE pg_catalog."default" );
  update terms set weight = (select weight + _added.count from _added where terms.id = _added.id)
    where terms.id in (select id from _added);
  with _rows as (
    insert into terms (value, weight) select value, count from _notadded returning id, value
  ) update _notadded set id = (select _rows.id from _rows where _notadded.value = _rows.value);
  update tf set term_count = term_count + (select count from _added where _added.id = tf.term_id)
    where tf.doc_id = $2 and tf.term_id in (select id from _added);
  insert into tf (doc_id, term_id, term_count) select $2, id, count from _added
    where not exists(select 1 from tf where tf.term_id = _added.id and tf.doc_id = $2);
  insert into tf (doc_id, term_id, term_count) select $2, id, count from _notadded;
  update docs set weight = weight + (select count(1) from _x) where id = $2;
  --return array(select coalesce(_x.id, _notadded.id) from _x left join _notadded on _x.value = _notadded.value);
  return null;
end;$_$;


ALTER FUNCTION public.terms_add(text[], bigint) OWNER TO postgres;

--
-- TOC entry 2081 (class 0 OID 0)
-- Dependencies: 236
-- Name: FUNCTION terms_add(text[], bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION terms_add(text[], bigint) IS 'author Bogdan Trofimov';


--
-- TOC entry 189 (class 1259 OID 553962)
-- Dependencies: 6
-- Name: _added; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE _added (
    id bigint,
    value text,
    count bigint
);


ALTER TABLE public._added OWNER TO postgres;

--
-- TOC entry 2082 (class 0 OID 0)
-- Dependencies: 189
-- Name: TABLE _added; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE _added IS 'author Bogdan Trofimov';


--
-- TOC entry 190 (class 1259 OID 553968)
-- Dependencies: 6
-- Name: _notadded; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE _notadded (
    id bigint,
    value text,
    count bigint
);


ALTER TABLE public._notadded OWNER TO postgres;

--
-- TOC entry 188 (class 1259 OID 553956)
-- Dependencies: 6
-- Name: _x; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE _x (
    id bigint,
    value text,
    count bigint
);


ALTER TABLE public._x OWNER TO postgres;

--
-- TOC entry 171 (class 1259 OID 16440)
-- Dependencies: 6
-- Name: config; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE config (
    id bigint NOT NULL,
    key text NOT NULL,
    value text,
    description text
);


ALTER TABLE public.config OWNER TO postgres;

--
-- TOC entry 2083 (class 0 OID 0)
-- Dependencies: 171
-- Name: TABLE config; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE config IS 'author Bogdan Trofimov';


--
-- TOC entry 172 (class 1259 OID 16446)
-- Dependencies: 6 171
-- Name: config_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.config_id_seq OWNER TO postgres;

--
-- TOC entry 2084 (class 0 OID 0)
-- Dependencies: 172
-- Name: config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE config_id_seq OWNED BY config.id;


--
-- TOC entry 2085 (class 0 OID 0)
-- Dependencies: 172
-- Name: config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('config_id_seq', 2, true);


--
-- TOC entry 173 (class 1259 OID 16448)
-- Dependencies: 6
-- Name: doc_term; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE doc_term (
    doc_id bigint NOT NULL,
    term_id bigint NOT NULL,
    seq_no integer NOT NULL
);


ALTER TABLE public.doc_term OWNER TO postgres;

--
-- TOC entry 2086 (class 0 OID 0)
-- Dependencies: 173
-- Name: TABLE doc_term; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE doc_term IS 'author Bogdan Trofimov';


--
-- TOC entry 174 (class 1259 OID 16451)
-- Dependencies: 1984 6
-- Name: docs; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE docs (
    id bigint NOT NULL,
    parent_id bigint,
    node text,
    weight integer NOT NULL,
    indexed boolean DEFAULT false NOT NULL
);


ALTER TABLE public.docs OWNER TO postgres;

--
-- TOC entry 2087 (class 0 OID 0)
-- Dependencies: 174
-- Name: TABLE docs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE docs IS 'author Bogdan Trofimov';


--
-- TOC entry 175 (class 1259 OID 16457)
-- Dependencies: 6 174
-- Name: docs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE docs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.docs_id_seq OWNER TO postgres;

--
-- TOC entry 2088 (class 0 OID 0)
-- Dependencies: 175
-- Name: docs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE docs_id_seq OWNED BY docs.id;


--
-- TOC entry 2089 (class 0 OID 0)
-- Dependencies: 175
-- Name: docs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('docs_id_seq', 2170, true);


--
-- TOC entry 176 (class 1259 OID 16459)
-- Dependencies: 6
-- Name: file_terms_rec; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE file_terms_rec (
    file_id bigint NOT NULL,
    terms text[] NOT NULL
);


ALTER TABLE public.file_terms_rec OWNER TO postgres;

--
-- TOC entry 2090 (class 0 OID 0)
-- Dependencies: 176
-- Name: TABLE file_terms_rec; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE file_terms_rec IS 'author Bogdan Trofimov';


--
-- TOC entry 177 (class 1259 OID 16465)
-- Dependencies: 6
-- Name: index_queue; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE index_queue (
    id bigint NOT NULL,
    path text
);


ALTER TABLE public.index_queue OWNER TO postgres;

--
-- TOC entry 2091 (class 0 OID 0)
-- Dependencies: 177
-- Name: TABLE index_queue; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE index_queue IS 'author Bogdan Trofimov';


--
-- TOC entry 178 (class 1259 OID 16471)
-- Dependencies: 6 177
-- Name: index_queue_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE index_queue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.index_queue_id_seq OWNER TO postgres;

--
-- TOC entry 2092 (class 0 OID 0)
-- Dependencies: 178
-- Name: index_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE index_queue_id_seq OWNED BY index_queue.id;


--
-- TOC entry 2093 (class 0 OID 0)
-- Dependencies: 178
-- Name: index_queue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('index_queue_id_seq', 531, true);


--
-- TOC entry 179 (class 1259 OID 16473)
-- Dependencies: 6
-- Name: neuron_doc; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE neuron_doc (
    neuron_id bigint NOT NULL,
    doc_id bigint NOT NULL
);


ALTER TABLE public.neuron_doc OWNER TO postgres;

--
-- TOC entry 2094 (class 0 OID 0)
-- Dependencies: 179
-- Name: TABLE neuron_doc; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE neuron_doc IS 'author Bogdan Trofimov';


--
-- TOC entry 180 (class 1259 OID 16476)
-- Dependencies: 1986 6
-- Name: neuron_neuron; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE neuron_neuron (
    neuron1_id bigint NOT NULL,
    neuron2_id bigint NOT NULL,
    age integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.neuron_neuron OWNER TO postgres;

--
-- TOC entry 2095 (class 0 OID 0)
-- Dependencies: 180
-- Name: TABLE neuron_neuron; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE neuron_neuron IS 'author Bogdan Trofimov';


--
-- TOC entry 181 (class 1259 OID 16480)
-- Dependencies: 6
-- Name: neuron_vectors; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE neuron_vectors (
    neuron_id bigint NOT NULL,
    term_id bigint NOT NULL,
    value double precision NOT NULL
);


ALTER TABLE public.neuron_vectors OWNER TO postgres;

--
-- TOC entry 2096 (class 0 OID 0)
-- Dependencies: 181
-- Name: TABLE neuron_vectors; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE neuron_vectors IS 'author Bogdan Trofimov';


--
-- TOC entry 182 (class 1259 OID 16483)
-- Dependencies: 1987 6
-- Name: neurons; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE neurons (
    id bigint NOT NULL,
    error double precision DEFAULT 0 NOT NULL
);


ALTER TABLE public.neurons OWNER TO postgres;

--
-- TOC entry 2097 (class 0 OID 0)
-- Dependencies: 182
-- Name: TABLE neurons; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE neurons IS 'author Bogdan Trofimov';


--
-- TOC entry 183 (class 1259 OID 16487)
-- Dependencies: 6 182
-- Name: neurons_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE neurons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.neurons_id_seq OWNER TO postgres;

--
-- TOC entry 2098 (class 0 OID 0)
-- Dependencies: 183
-- Name: neurons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE neurons_id_seq OWNED BY neurons.id;


--
-- TOC entry 2099 (class 0 OID 0)
-- Dependencies: 183
-- Name: neurons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('neurons_id_seq', 139, true);


--
-- TOC entry 184 (class 1259 OID 16489)
-- Dependencies: 6
-- Name: terms; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE terms (
    id bigint NOT NULL,
    value text NOT NULL,
    weight integer NOT NULL
);


ALTER TABLE public.terms OWNER TO postgres;

--
-- TOC entry 2100 (class 0 OID 0)
-- Dependencies: 184
-- Name: TABLE terms; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE terms IS 'author Bogdan Trofimov';


--
-- TOC entry 185 (class 1259 OID 16495)
-- Dependencies: 6 184
-- Name: terms_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE terms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.terms_id_seq OWNER TO postgres;

--
-- TOC entry 2101 (class 0 OID 0)
-- Dependencies: 185
-- Name: terms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE terms_id_seq OWNED BY terms.id;


--
-- TOC entry 2102 (class 0 OID 0)
-- Dependencies: 185
-- Name: terms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('terms_id_seq', 1754506, true);


--
-- TOC entry 186 (class 1259 OID 16497)
-- Dependencies: 6
-- Name: tf; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE tf (
    doc_id bigint NOT NULL,
    term_id bigint NOT NULL,
    term_count integer NOT NULL
);


ALTER TABLE public.tf OWNER TO postgres;

--
-- TOC entry 2103 (class 0 OID 0)
-- Dependencies: 186
-- Name: TABLE tf; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE tf IS 'author Bogdan Trofimov';


--
-- TOC entry 187 (class 1259 OID 16500)
-- Dependencies: 6
-- Name: variables; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE variables (
    name text NOT NULL,
    ivalue bigint,
    dvalue double precision
);


ALTER TABLE public.variables OWNER TO postgres;

--
-- TOC entry 2104 (class 0 OID 0)
-- Dependencies: 187
-- Name: TABLE variables; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE variables IS 'author Bogdan Trofimov';


--
-- TOC entry 1982 (class 2604 OID 16506)
-- Dependencies: 172 171
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY config ALTER COLUMN id SET DEFAULT nextval('config_id_seq'::regclass);


--
-- TOC entry 1983 (class 2604 OID 16507)
-- Dependencies: 175 174
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY docs ALTER COLUMN id SET DEFAULT nextval('docs_id_seq'::regclass);


--
-- TOC entry 1985 (class 2604 OID 16508)
-- Dependencies: 178 177
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY index_queue ALTER COLUMN id SET DEFAULT nextval('index_queue_id_seq'::regclass);


--
-- TOC entry 1988 (class 2604 OID 16509)
-- Dependencies: 183 182
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY neurons ALTER COLUMN id SET DEFAULT nextval('neurons_id_seq'::regclass);


--
-- TOC entry 1989 (class 2604 OID 16510)
-- Dependencies: 185 184
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY terms ALTER COLUMN id SET DEFAULT nextval('terms_id_seq'::regclass);
