-- Fan song requests for jordanmackintoshofficial.github.io
-- Paste this whole file into Supabase: SQL Editor > New query > Run.

create table if not exists public.song_requests (
  id bigint generated always as identity primary key,
  song text not null check (char_length(song) between 1 and 80),
  artist text not null default '' check (char_length(artist) <= 60),
  votes integer not null default 1,
  hidden boolean not null default false,   -- set to true in the Table Editor to remove a request from the site
  created_at timestamptz not null default now()
);
create unique index if not exists song_requests_unique on public.song_requests (lower(song), lower(artist));

alter table public.song_requests enable row level security;
drop policy if exists "Anyone can read visible requests" on public.song_requests;
create policy "Anyone can read visible requests" on public.song_requests
  for select to anon using (hidden = false);

-- New request, or +1 vote if the same song was already requested
create or replace function public.request_song(p_song text, p_artist text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if char_length(trim(coalesce(p_song,''))) = 0 or char_length(p_song) > 80 or char_length(coalesce(p_artist,'')) > 60 then
    raise exception 'invalid request';
  end if;
  insert into song_requests (song, artist) values (trim(p_song), trim(coalesce(p_artist,'')))
  on conflict ((lower(song)), (lower(artist))) do update set votes = song_requests.votes + 1;
end $$;

create or replace function public.vote_song(p_id bigint)
returns void language sql security definer set search_path = public as $$
  update song_requests set votes = votes + 1 where id = p_id and hidden = false;
$$;

grant execute on function public.request_song(text, text) to anon;
grant execute on function public.vote_song(bigint) to anon;
